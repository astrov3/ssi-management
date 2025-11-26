import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/features/dashboard/dialogs/admin_panel_dialog.dart';
import 'package:ssi_app/features/dashboard/dialogs/register_did_dialog.dart';
import 'package:ssi_app/features/dashboard/widgets/dashboard_header.dart';
import 'package:ssi_app/features/dashboard/widgets/did_status_card.dart';
import 'package:ssi_app/features/dashboard/widgets/loading_state.dart';
import 'package:ssi_app/features/dashboard/widgets/quick_actions.dart';
import 'package:ssi_app/features/dashboard/widgets/statistics_row.dart';
import 'package:ssi_app/features/dashboard/widgets/wallet_card.dart';
import 'package:ssi_app/features/did/view/did_management_screen.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:ssi_app/services/role/role_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/wallet/wallet_name_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _web3Service = Web3Service();
  final _walletConnectService = WalletConnectService();
  final _roleService = RoleService();
  final _walletNameService = WalletNameService();
  final _pinataService = PinataService();
  String _address = 'Loading...';
  int _vcCount = 0;
  int _verifiedCount = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _didData;
  bool _isOwner = false;
  bool _isAdmin = false;
  bool _isVerifier = false;
  String _walletName = 'SSI Account';

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void dispose() {
    _roleService.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    try {
      // Try to load from Web3Service first (private key wallet)
      String? address = await _web3Service.loadWallet();
      
      // If not found, try WalletConnect service
      if (address == null) {
        debugPrint('[Dashboard] No private key wallet, checking WalletConnect...');
        address = await _walletConnectService.getStoredAddress();
        debugPrint('[Dashboard] WalletConnect address: $address');
      }
      
      if (address == null || address.isEmpty) {
        debugPrint('[Dashboard] No wallet address found');
        if (!mounted) return;
        setState(() {
          _address = 'No wallet connected';
          _isLoading = false;
        });
        return;
      }

      final vcs = await _safeFetchVCs(address);
      
      // Count verified credentials (only those verified by trusted verifier)
      final verifiedCount = vcs.where((vc) => vc['verified'] == true).length;

      // Check DID status
      Map<String, dynamic>? didData;
      bool isOwner = false;
      try {
        didData = await _web3Service.getDID(address);
        if (didData != null) {
          isOwner = didData['owner'].toString().toLowerCase() == address.toLowerCase() && didData['active'] == true;
        }
      } catch (_) {
        // DID doesn't exist yet
      }

      // Get wallet name
      final walletName = await _walletNameService.getWalletName(address);

      // Check admin and verifier status
      bool isAdmin = false;
      bool isVerifier = false;
      try {
        final admin = await _web3Service.getAdmin();
        isAdmin = admin != null && admin.toLowerCase() == address.toLowerCase();
        
        isVerifier = await _web3Service.isTrustedVerifier(address);
      } catch (e) {
        debugPrint('[Dashboard] Error checking admin/verifier status: $e');
      }

      // Note: All users are owners and issuers by default
      // They can only authorize others to issue VCs for their DID
      // No need to check user role preference - users are always both

      if (!mounted) return;
      setState(() {
        _address = address!;
        _vcCount = vcs.length;
        _verifiedCount = verifiedCount;
        _didData = didData;
        _isOwner = isOwner;
        _isAdmin = isAdmin;
        _isVerifier = isVerifier;
        _walletName = walletName ?? 'SSI Account';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[Dashboard] Error loading wallet data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _safeFetchVCs(String orgID) async {
    try {
      return await _web3Service.getVCs(orgID);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  String _shortenAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
  }

  void _copyToClipboard(String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const LoadingState()
            : RefreshIndicator(
                onRefresh: _loadWalletData,
                color: AppColors.secondary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DashboardHeader(
                        walletName: _walletName,
                        onNotificationsTap: () {},
                      ),
                      const SizedBox(height: 24),
                      WalletCard(
                        address: _address,
                        walletName: _walletName,
                        formattedAddress: _shortenAddress(_address),
                        onCopy: () => _copyToClipboard(_address, AppLocalizations.of(context)!.addressCopied),
                      ),
                      const SizedBox(height: 32),
                      StatisticsRow(vcCount: _vcCount, verifiedCount: _verifiedCount),
                      if (_didData != null) ...[
                        const SizedBox(height: 24),
                        DIDStatusCard(
                          didData: _didData!,
                          isOwner: _isOwner,
                          onManageTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DIDManagementScreen()),
                            ).then((_) => _loadWalletData());
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                      QuickActions(
                        orgId: _address,
                        isOwnerOnChain: _isOwner,
                        isAdmin: _isAdmin,
                        isVerifier: _isVerifier,
                        onRegister: _showRegisterDIDDialog,
                        onManageDID: _didData != null && _isOwner
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DIDManagementScreen()),
                                ).then((_) => _loadWalletData());
                              }
                            : null,
                        onAdminPanel: _isAdmin ? _showAdminPanel : null,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _showRegisterDIDDialog() {
    final orgIDController = TextEditingController(text: _address);

    showDialog<void>(
      context: context,
      builder: (context) => RegisterDidDialog(
        orgIDController: orgIDController,
        onSubmit: (orgID, uri, metadata) async {
          await _registerDID(orgID, metadata);
        },
      ),
    );
  }

  void _showAdminPanel() {
    showDialog<void>(
      context: context,
      builder: (context) => AdminPanelDialog(
        onSubmit: (verifierAddress, isAdding) async {
          await _setTrustedVerifier(verifierAddress, isAdding);
        },
      ),
    );
  }

  Future<void> _setTrustedVerifier(String verifierAddress, bool allowed) async {
    final navigator = Navigator.of(context);
    try {
      _showBlockingSpinner();
      final txHash = await _web3Service.setTrustedVerifier(verifierAddress, allowed);
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trusted verifier ${allowed ? 'added' : 'removed'}: ${txHash.substring(0, 10)}...'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadWalletData();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _registerDID(String orgID, Map<String, dynamic>? metadata) async {
    final navigator = Navigator.of(context);
    try {
      _showBlockingSpinner('Đang tạo DID document và upload lên IPFS...');

      // Handle file uploads if any
      String? logoIpfsUri;
      String? documentIpfsUri;
      Map<String, dynamic> finalMetadata = {};
      
      if (metadata != null) {
        // Upload logo if provided
        if (metadata.containsKey('logoPath') && metadata['logoPath'] != null) {
          try {
            final logoFile = File(metadata['logoPath'] as String);
            if (await logoFile.exists()) {
              _updateSpinnerMessage('Đang upload logo lên IPFS...');
              final logoBytes = await logoFile.readAsBytes();
              final logoFileName = logoFile.path.split('/').last;
              logoIpfsUri = await _pinataService.uploadFile(logoBytes, logoFileName);
              finalMetadata['logo'] = logoIpfsUri;
            }
          } catch (e) {
            debugPrint('Error uploading logo: $e');
          }
        }

        // Upload document if provided
        if (metadata.containsKey('documentPath') && metadata['documentPath'] != null) {
          try {
            final docFile = File(metadata['documentPath'] as String);
            if (await docFile.exists()) {
              _updateSpinnerMessage('Đang upload tài liệu lên IPFS...');
              final docBytes = await docFile.readAsBytes();
              final docFileName = docFile.path.split('/').last;
              documentIpfsUri = await _pinataService.uploadFile(docBytes, docFileName);
              finalMetadata['document'] = documentIpfsUri;

              // If JSON, parse and merge metadata
              final extension = docFile.path.split('.').last.toLowerCase();
              if (extension == 'json') {
                try {
                  final jsonContent = await docFile.readAsString();
                  final docData = jsonDecode(jsonContent) as Map<String, dynamic>?;
                  if (docData != null) {
                    finalMetadata.addAll(docData);
                    finalMetadata['document'] = documentIpfsUri;
                  }
                } catch (e) {
                  debugPrint('Error parsing document JSON: $e');
                }
              }
            }
          } catch (e) {
            debugPrint('Error uploading document: $e');
          }
        }

        // Add other metadata fields
        finalMetadata.addAll({
          if (metadata.containsKey('name') && metadata['name'] != null) 'name': metadata['name'],
          if (metadata.containsKey('description') && metadata['description'] != null) 'description': metadata['description'],
          if (metadata.containsKey('email') && metadata['email'] != null) 'email': metadata['email'],
          if (metadata.containsKey('website') && metadata['website'] != null) 'website': metadata['website'],
          if (metadata.containsKey('address') && metadata['address'] != null) 'address': metadata['address'],
          if (metadata.containsKey('phone') && metadata['phone'] != null) 'phone': metadata['phone'],
        });
      }

      // Ensure we have at least a name
      if (!finalMetadata.containsKey('name') || finalMetadata['name'] == null || finalMetadata['name'].toString().isEmpty) {
        finalMetadata['name'] = 'DID ${orgID.substring(0, orgID.length > 8 ? 8 : orgID.length)}...';
      }

      _updateSpinnerMessage('Đang tạo DID document...');

      // Get current address for controller
      String? currentAddress;
      try {
        currentAddress = await _web3Service.loadWallet();
        if (currentAddress == null) {
          currentAddress = await _walletConnectService.getStoredAddress();
        }
      } catch (e) {
        debugPrint('Error getting current address: $e');
      }

      if (currentAddress == null) {
        throw StateError('Không thể lấy địa chỉ ví hiện tại');
      }

      // Create DID document
      final didDocument = _pinataService.createDIDDocument(
        id: 'did:ethr:$orgID',
        controller: currentAddress,
        serviceEndpoint: finalMetadata['website']?.toString() ?? 'https://ssi.example.com',
        metadata: finalMetadata.isEmpty ? null : finalMetadata,
      );

      // Upload to IPFS
      final ipfsUri = await _pinataService.uploadJSON(didDocument);
      final hashData = _pinataService.generateHash(didDocument);

      // Check if using WalletConnect
      final isWC = await _walletConnectService.isConnected();
      if (isWC) {
        _updateSpinnerMessage('Đang gửi transaction đến MetaMask...\n\nVui lòng mở MetaMask wallet và xác nhận transaction.');
      } else {
        _updateSpinnerMessage('Đang đăng ký DID trên blockchain...');
      }

      // Register DID on blockchain
      final txHash = await _web3Service.registerDID(orgID, hashData, ipfsUri);
      
      navigator.pop();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.didRegistered('${txHash.substring(0, 10)}...')),
          backgroundColor: AppColors.success,
        ),
      );
      _loadWalletData();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: AppColors.danger),
      );
    }
  }

  void _updateSpinnerMessage(String message) {
    Navigator.of(context).pop();
    _showBlockingSpinner(message);
  }


  void _showBlockingSpinner([String? message]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.secondary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

