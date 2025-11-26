import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/features/did/dialogs/authorize_issuer_dialog.dart';
import 'package:ssi_app/features/did/dialogs/did_details_dialog.dart';
import 'package:ssi_app/features/did/dialogs/register_did_dialog.dart';
import 'package:ssi_app/features/did/dialogs/update_did_dialog.dart';
import 'package:ssi_app/features/did/widgets/action_button.dart';
import 'package:ssi_app/features/did/widgets/did_info_card.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:ssi_app/services/role/role_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';

class DIDManagementScreen extends StatefulWidget {
  const DIDManagementScreen({super.key});

  @override
  State<DIDManagementScreen> createState() => _DIDManagementScreenState();
}

class _DIDManagementScreenState extends State<DIDManagementScreen> {
  final _web3Service = Web3Service();
  final _roleService = RoleService();
  final _pinataService = PinataService();
  
  String? _currentAddress;
  String? _currentOrgID;
  Map<String, dynamic>? _didData;
  bool _isLoading = true;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _roleService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final address = await _roleService.getCurrentAddress();
      if (address == null || address.isEmpty) {
        if (!mounted) return;
        setState(() {
          _currentAddress = null;
          _isLoading = false;
        });
        return;
      }

      setState(() => _currentAddress = address);
      
      // Use address as default orgID for testing, or allow user to specify
      final orgID = address;
      _currentOrgID = orgID;

      try {
        final did = await _web3Service.getDID(orgID);
        if (did == null) {
          // DID doesn't exist yet
          if (!mounted) return;
          setState(() {
            _didData = null;
            _isOwner = false;
            _isLoading = false;
          });
          return;
        }
        
        final isOwner = await _roleService.isOwnerOf(orgID, address);
        
        if (!mounted) return;
        setState(() {
          _didData = did;
          _isOwner = isOwner;
          _isLoading = false;
        });
      } catch (_) {
        // Error occurred
        if (!mounted) return;
        setState(() {
          _didData = null;
          _isOwner = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading DID data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerDID() async {
    if (_currentAddress == null) {
      _showError('Không tìm thấy địa chỉ ví');
      return;
    }

    final orgIDController = TextEditingController(text: _currentAddress);
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final emailController = TextEditingController();
    final websiteController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => RegisterDIDDialog(
        orgIDController: orgIDController,
        nameController: nameController,
        descriptionController: descriptionController,
        emailController: emailController,
        websiteController: websiteController,
        addressController: addressController,
        phoneController: phoneController,
      ),
    );

    if (result == null) return;

    final selectedTab = result['tab'] as int? ?? 0;
    final logoPath = result['logoPath'] as String?;
    final documentPath = result['documentPath'] as String?;

    try {
      _showBlockingSpinner('Đang tạo DID document và upload lên IPFS...');

      // Handle file uploads if any
      String? logoIpfsUri;
      String? documentIpfsUri;
      String? logoFileName;
      String? documentFileName;
      
      if (logoPath != null && logoPath.isNotEmpty) {
        try {
          final logoFile = File(logoPath);
          if (await logoFile.exists()) {
            _updateSpinnerMessage('Đang upload logo lên IPFS...');
            final logoBytes = await logoFile.readAsBytes();
            logoFileName = logoFile.path.split('/').last;
            logoIpfsUri = await _pinataService.uploadFile(logoBytes, logoFileName);
          }
        } catch (e) {
          debugPrint('Error uploading logo: $e');
        }
      }

      if (documentPath != null && documentPath.isNotEmpty) {
        try {
          final docFile = File(documentPath);
          if (await docFile.exists()) {
            _updateSpinnerMessage('Đang upload tài liệu lên IPFS...');
            final docBytes = await docFile.readAsBytes();
            documentFileName = docFile.path.split('/').last;
            documentIpfsUri = await _pinataService.uploadFile(docBytes, documentFileName);
          }
        } catch (e) {
          debugPrint('Error uploading document: $e');
        }
      }

      // Create DID document with metadata
      final metadata = <String, dynamic>{};
      
      // If using form tab, collect form data
      if (selectedTab == 0) {
        if (nameController.text.isNotEmpty) {
          metadata['name'] = nameController.text.trim();
        }
        if (descriptionController.text.isNotEmpty) {
          metadata['description'] = descriptionController.text.trim();
        }
        if (emailController.text.isNotEmpty) {
          metadata['email'] = emailController.text.trim();
        }
        if (websiteController.text.isNotEmpty) {
          metadata['website'] = websiteController.text.trim();
        }
        if (addressController.text.isNotEmpty) {
          metadata['address'] = addressController.text.trim();
        }
        if (phoneController.text.isNotEmpty) {
          metadata['phone'] = phoneController.text.trim();
        }
        if (logoIpfsUri != null) {
          metadata['logo'] = logoIpfsUri;
          if (logoFileName != null) {
            metadata['logoFileName'] = logoFileName;
          }
        }
      }

      // If document was uploaded, add it to metadata
      if (documentIpfsUri != null) {
        metadata['document'] = documentIpfsUri;
        if (documentFileName != null) {
          metadata['documentFileName'] = documentFileName;
        }
      }

      // If document was uploaded and is JSON, try to parse it and merge metadata
      if (documentPath != null && documentPath.isNotEmpty) {
        final docFile = File(documentPath);
        try {
          if (await docFile.exists()) {
            final extension = docFile.path.split('.').last.toLowerCase();
            if (extension == 'json') {
              _updateSpinnerMessage('Đang phân tích file JSON...');
              final jsonContent = await docFile.readAsString();
              final docData = jsonDecode(jsonContent) as Map<String, dynamic>?;
              if (docData != null) {
                // Merge document data into metadata (document data takes priority for upload tab)
                if (selectedTab == 1) {
                  // Upload tab: use document data as primary source
                  metadata.clear();
                  metadata.addAll(docData);
                  if (documentIpfsUri != null) {
                    metadata['document'] = documentIpfsUri;
                    if (documentFileName != null) {
                      metadata['documentFileName'] = documentFileName;
                    }
                  }
                } else {
                  // Form tab: merge document data (avoid overwriting form fields)
                  docData.forEach((key, value) {
                    if (!metadata.containsKey(key) && value != null) {
                      metadata[key] = value;
                    }
                  });
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing document JSON: $e');
          // If JSON parsing fails but we're on upload tab, at least set a name
          if (selectedTab == 1 && !metadata.containsKey('name')) {
            metadata['name'] = 'DID from ${docFile.path.split('/').last}';
          }
        }
      }

      // Ensure we have at least a name
      if (!metadata.containsKey('name') || metadata['name'] == null || metadata['name'].toString().isEmpty) {
        final address = _currentAddress ?? '';
        metadata['name'] = 'DID ${address.isNotEmpty ? address.substring(0, address.length > 8 ? 8 : address.length) : 'unknown'}...';
      }

      _updateSpinnerMessage('Đang tạo DID document...');

      final didDocument = _pinataService.createDIDDocument(
        id: 'did:ethr:${orgIDController.text}',
        controller: _currentAddress!,
        serviceEndpoint: websiteController.text.isNotEmpty 
            ? websiteController.text.trim() 
            : 'https://ssi.example.com',
        metadata: metadata.isEmpty ? null : metadata,
      );

      // Upload to IPFS
      final ipfsUri = await _pinataService.uploadJSON(didDocument);
      final hashData = _pinataService.generateHash(didDocument);

      // Check if using WalletConnect
      final walletConnectService = WalletConnectService();
      final isWC = await walletConnectService.isConnected();
      
      if (isWC) {
        // Update spinner message for WalletConnect transaction
        _updateSpinnerMessage('Đang gửi transaction đến MetaMask...\n\nVui lòng mở MetaMask wallet và xác nhận transaction.\n\nNếu không thấy notification, vui lòng mở MetaMask app thủ công.');
      } else {
        _updateSpinnerMessage('Đang đăng ký DID trên blockchain...');
      }

      // Register DID on blockchain
      final txHash = await _web3Service.registerDID(orgIDController.text, hashData, ipfsUri);

      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showSuccess('DID đã được đăng ký thành công!\nTransaction: ${txHash.substring(0, 10)}...');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      
      // Provide more helpful error messages
      String errorMessage = 'Lỗi đăng ký DID: $e';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Transaction timeout. Vui lòng kiểm tra MetaMask wallet và xác nhận transaction, sau đó thử lại.';
      } else if (e.toString().contains('rejected') || e.toString().contains('denied')) {
        errorMessage = 'Transaction đã bị từ chối trong MetaMask wallet.';
      } else if (e.toString().contains('session') && e.toString().contains('disconnected')) {
        errorMessage = 'WalletConnect session đã bị ngắt kết nối. Vui lòng kết nối lại wallet.';
      }
      
      _showError(errorMessage);
    }
  }

  Future<void> _updateDID() async {
    if (_currentOrgID == null || !_isOwner) {
      _showError('Bạn không có quyền cập nhật DID này');
      return;
    }

    // Load existing DID document from IPFS to pre-fill form
    Map<String, dynamic>? existingDoc;
    String? existingUri;
    try {
      if (_didData != null) {
        existingUri = _didData!['uri'] as String?;
        if (existingUri != null && existingUri.isNotEmpty) {
          try {
            existingDoc = await _pinataService.getJSON(existingUri);
          } catch (e) {
            debugPrint('Error loading existing DID document: $e');
            // Continue without existing document
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting existing DID document: $e');
    }

    // Extract existing metadata from document
    Map<String, dynamic>? existingMetadata;
    String? existingServiceEndpoint;
    if (existingDoc != null) {
      existingMetadata = existingDoc['metadata'] as Map<String, dynamic>?;
      // Try to get serviceEndpoint from service array
      if (existingDoc['service'] != null) {
        final services = existingDoc['service'] as List<dynamic>?;
        if (services != null && services.isNotEmpty) {
          final service = services.first as Map<String, dynamic>?;
          existingServiceEndpoint = service?['serviceEndpoint'] as String?;
        }
      }
    }

    final nameController = TextEditingController(text: existingMetadata?['name']?.toString() ?? '');
    final descriptionController = TextEditingController(text: existingMetadata?['description']?.toString() ?? '');
    final emailController = TextEditingController(text: existingMetadata?['email']?.toString() ?? '');
    final websiteController = TextEditingController(text: existingServiceEndpoint ?? existingMetadata?['website']?.toString() ?? '');
    final addressController = TextEditingController(text: existingMetadata?['address']?.toString() ?? '');
    final phoneController = TextEditingController(text: existingMetadata?['phone']?.toString() ?? '');

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDIDDialog(
        nameController: nameController,
        descriptionController: descriptionController,
        emailController: emailController,
        websiteController: websiteController,
        addressController: addressController,
        phoneController: phoneController,
      ),
    );

    if (result == null) return;

    final selectedTab = result['tab'] as int? ?? 0;
    final logoPath = result['logoPath'] as String?;
    final documentPath = result['documentPath'] as String?;

    try {
      _showBlockingSpinner('Đang cập nhật DID document và upload lên IPFS...');

      // Handle file uploads if any
      String? logoIpfsUri;
      String? documentIpfsUri;
      String? logoFileName;
      String? documentFileName;
      
      if (logoPath != null && logoPath.isNotEmpty) {
        try {
          final logoFile = File(logoPath);
          if (await logoFile.exists()) {
            _updateSpinnerMessage('Đang upload logo lên IPFS...');
            final logoBytes = await logoFile.readAsBytes();
            logoFileName = logoFile.path.split('/').last;
            logoIpfsUri = await _pinataService.uploadFile(logoBytes, logoFileName);
          }
        } catch (e) {
          debugPrint('Error uploading logo: $e');
        }
      }

      if (documentPath != null && documentPath.isNotEmpty) {
        try {
          final docFile = File(documentPath);
          if (await docFile.exists()) {
            _updateSpinnerMessage('Đang upload tài liệu lên IPFS...');
            final docBytes = await docFile.readAsBytes();
            documentFileName = docFile.path.split('/').last;
            documentIpfsUri = await _pinataService.uploadFile(docBytes, documentFileName);
          }
        } catch (e) {
          debugPrint('Error uploading document: $e');
        }
      }

      // Build updated metadata - start with existing metadata if available
      final metadata = <String, dynamic>{};
      if (existingMetadata != null) {
        metadata.addAll(existingMetadata);
      }

      // If using form tab, update with form data
      if (selectedTab == 0) {
        if (nameController.text.isNotEmpty) {
          metadata['name'] = nameController.text.trim();
        } else if (metadata.containsKey('name')) {
          metadata.remove('name');
        }
        if (descriptionController.text.isNotEmpty) {
          metadata['description'] = descriptionController.text.trim();
        } else if (metadata.containsKey('description')) {
          metadata.remove('description');
        }
        if (emailController.text.isNotEmpty) {
          metadata['email'] = emailController.text.trim();
        } else if (metadata.containsKey('email')) {
          metadata.remove('email');
        }
        if (websiteController.text.isNotEmpty) {
          metadata['website'] = websiteController.text.trim();
        } else if (metadata.containsKey('website')) {
          metadata.remove('website');
        }
        if (addressController.text.isNotEmpty) {
          metadata['address'] = addressController.text.trim();
        } else if (metadata.containsKey('address')) {
          metadata.remove('address');
        }
        if (phoneController.text.isNotEmpty) {
          metadata['phone'] = phoneController.text.trim();
        } else if (metadata.containsKey('phone')) {
          metadata.remove('phone');
        }
        if (logoIpfsUri != null) {
          metadata['logo'] = logoIpfsUri;
          if (logoFileName != null) {
            metadata['logoFileName'] = logoFileName;
          }
        }
      }

      // If document was uploaded, add it to metadata
      if (documentIpfsUri != null) {
        metadata['document'] = documentIpfsUri;
        if (documentFileName != null) {
          metadata['documentFileName'] = documentFileName;
        }
      }

      // If document was uploaded and is JSON, try to parse it and merge metadata
      if (documentPath != null && documentPath.isNotEmpty) {
        final docFile = File(documentPath);
        try {
          if (await docFile.exists()) {
            final extension = docFile.path.split('.').last.toLowerCase();
            if (extension == 'json') {
              _updateSpinnerMessage('Đang phân tích file JSON...');
              final jsonContent = await docFile.readAsString();
              final docData = jsonDecode(jsonContent) as Map<String, dynamic>?;
              if (docData != null) {
                // Merge document data into metadata (document data takes priority for upload tab)
                if (selectedTab == 1) {
                  // Upload tab: use document data as primary source
                  metadata.clear();
                  metadata.addAll(docData);
                  if (documentIpfsUri != null) {
                    metadata['document'] = documentIpfsUri;
                    if (documentFileName != null) {
                      metadata['documentFileName'] = documentFileName;
                    }
                  }
                } else {
                  // Form tab: merge document data (avoid overwriting form fields)
                  docData.forEach((key, value) {
                    if (!metadata.containsKey(key) && value != null) {
                      metadata[key] = value;
                    }
                  });
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing document JSON: $e');
        }
      }

      // Determine service endpoint
      String serviceEndpoint = 'https://ssi.example.com';
      if (websiteController.text.isNotEmpty) {
        serviceEndpoint = websiteController.text.trim();
      } else if (existingServiceEndpoint != null && existingServiceEndpoint.isNotEmpty) {
        serviceEndpoint = existingServiceEndpoint;
      } else if (metadata.containsKey('website') && metadata['website'] != null) {
        serviceEndpoint = metadata['website'].toString();
      }

      _updateSpinnerMessage('Đang tạo DID document...');

      // Create updated DID document - merge with existing document structure if available
      Map<String, dynamic> didDocument;
      if (existingDoc != null) {
        // Start with existing document structure
        didDocument = Map<String, dynamic>.from(existingDoc);
        // Update fields
        didDocument['id'] = 'did:ethr:$_currentOrgID';
        didDocument['controller'] = _currentAddress!;
        didDocument['updated'] = DateTime.now().toIso8601String();
        
        // Update service endpoint
        if (serviceEndpoint.isNotEmpty) {
          didDocument['service'] = [
            {
              'id': 'did:ethr:$_currentOrgID#service-1',
              'type': 'LinkedDomains',
              'serviceEndpoint': serviceEndpoint,
            },
          ];
        }
        
        // Update metadata
        if (metadata.isNotEmpty) {
          didDocument['metadata'] = metadata;
        } else {
          didDocument.remove('metadata');
        }
      } else {
        // Create new document structure
        didDocument = _pinataService.createDIDDocument(
          id: 'did:ethr:$_currentOrgID',
          controller: _currentAddress!,
          serviceEndpoint: serviceEndpoint,
          metadata: metadata.isEmpty ? null : metadata,
        );
      }

      // Upload to IPFS
      final ipfsUri = await _pinataService.uploadJSON(didDocument);
      final hashData = _pinataService.generateHash(didDocument);

      // Check if using WalletConnect
      final walletConnectService = WalletConnectService();
      final isWC = await walletConnectService.isConnected();
      
      if (isWC) {
        // Update spinner message for WalletConnect transaction
        _updateSpinnerMessage('Đang gửi transaction đến MetaMask...\n\nVui lòng mở MetaMask wallet và xác nhận transaction.\n\nNếu không thấy notification, vui lòng mở MetaMask app thủ công.');
      } else {
        _updateSpinnerMessage('Đang cập nhật DID trên blockchain...');
      }

      // Update DID on blockchain
      final txHash = await _web3Service.updateDID(_currentOrgID!, hashData, ipfsUri);

      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showSuccess('DID đã được cập nhật thành công!\nTransaction: ${txHash.substring(0, 10)}...');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      
      // Provide more helpful error messages
      String errorMessage = 'Lỗi cập nhật DID: $e';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Transaction timeout. Vui lòng kiểm tra MetaMask wallet và xác nhận transaction, sau đó thử lại.';
      } else if (e.toString().contains('rejected') || e.toString().contains('denied')) {
        errorMessage = 'Transaction đã bị từ chối trong MetaMask wallet.';
      } else if (e.toString().contains('session') && e.toString().contains('disconnected')) {
        errorMessage = 'WalletConnect session đã bị ngắt kết nối. Vui lòng kết nối lại wallet.';
      }
      
      _showError(errorMessage);
    }
  }

  Future<void> _deactivateDID() async {
    if (_currentOrgID == null || !_isOwner) {
      _showError('Bạn không có quyền vô hiệu hóa DID này');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xác nhận vô hiệu hóa DID', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc chắn muốn vô hiệu hóa DID này? Sau khi vô hiệu hóa, bạn sẽ không thể phát hành VC mới.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _showBlockingSpinner('Đang vô hiệu hóa DID...');
      await _web3Service.deactivateDID(_currentOrgID!);

      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showSuccess('DID đã được vô hiệu hóa');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showError('Lỗi vô hiệu hóa DID: $e');
    }
  }

  Future<void> _authorizeIssuer() async {
    if (_currentOrgID == null || !_isOwner) {
      _showError('Bạn không có quyền ủy quyền issuer');
      return;
    }

    final issuerController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AuthorizeIssuerDialog(
        issuerController: issuerController,
      ),
    );

    if (confirmed != true) return;

    final issuerAddress = issuerController.text.trim();
    if (!_isValidAddress(issuerAddress)) {
      _showError('Địa chỉ issuer không hợp lệ');
      return;
    }

    try {
      _showBlockingSpinner('Đang ủy quyền issuer...');
      await _web3Service.authorizeIssuer(_currentOrgID!, issuerAddress);

      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showSuccess('Issuer đã được ủy quyền thành công!');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showError('Lỗi ủy quyền issuer: $e');
    }
  }

  Future<void> _showDIDDetails() async {
    if (_currentOrgID == null || _didData == null) {
      _showError('Không có thông tin DID');
      return;
    }

    // Load DID document from IPFS
    Map<String, dynamic>? didDocument;
    try {
      final uri = _didData!['uri'] as String?;
      if (uri != null && uri.isNotEmpty) {
        didDocument = await _pinataService.getJSON(uri);
      }
    } catch (e) {
      debugPrint('Error loading DID document: $e');
      // Continue without document
    }

    if (!mounted) return;

    // Prepare DID data for dialog
    final didDataForDialog = {
      'orgID': _currentOrgID!,
      'owner': _didData!['owner'],
      'hashData': _didData!['hashData'],
      'uri': _didData!['uri'],
      'active': _didData!['active'],
    };

    showDialog<void>(
      context: context,
      builder: (context) => DIDDetailsDialog(
        didData: didDataForDialog,
        didDocument: didDocument,
        pinataService: _pinataService,
      ),
    );
  }

  bool _isValidAddress(String address) {
    return address.startsWith('0x') && address.length == 42;
  }

  void _showBlockingSpinner(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            if (message.contains('MetaMask') || message.contains('wallet'))
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Vui lòng mở MetaMask và xác nhận transaction',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _updateSpinnerMessage(String message) {
    // Try to update the existing dialog if possible
    // This is a workaround - ideally we'd use a StatefulBuilder
    Navigator.of(context).pop();
    _showBlockingSpinner(message);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[900]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        title: Text(
          'Quản lý DID',
          style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[900]),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : _currentAddress == null
              ? _buildNoWalletView()
              : _didData == null
                  ? _buildNoDIDView()
                  : _buildDIDView(),
    );
  }

  Widget _buildNoWalletView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wallet_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa kết nối ví',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDIDView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.person_add_outlined, size: 64, color: AppColors.secondary),
                const SizedBox(height: 16),
                Text(
                  'Chưa có DID',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[900]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng ký DID để bắt đầu sử dụng dịch vụ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _registerDID,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đăng ký DID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDIDView() {
    final owner = _didData!['owner'] as String;
    final uri = _didData!['uri'] as String;
    final active = _didData!['active'] as bool;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DIDInfoCard(
            orgID: _currentOrgID!,
            owner: owner,
            uri: uri,
            active: active,
          ),
          const SizedBox(height: 24),
          ActionButton(
            icon: Icons.info_outline,
            label: 'Xem chi tiết',
            color: const Color(0xFF6366F1),
            onPressed: _showDIDDetails,
          ),
          const SizedBox(height: 12),
          if (_isOwner && active) ...[
            ActionButton(
              icon: Icons.edit,
              label: 'Cập nhật DID',
              color: AppColors.secondary,
              onPressed: _updateDID,
            ),
            const SizedBox(height: 12),
            ActionButton(
              icon: Icons.person_add,
              label: 'Ủy quyền Issuer',
              color: const Color(0xFF3B82F6),
              onPressed: _authorizeIssuer,
            ),
            const SizedBox(height: 12),
            ActionButton(
              icon: Icons.block,
              label: 'Vô hiệu hóa DID',
              color: AppColors.danger,
              onPressed: _deactivateDID,
            ),
          ] else if (!active) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'DID đã bị vô hiệu hóa',
                      style: TextStyle(color: Colors.grey[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
