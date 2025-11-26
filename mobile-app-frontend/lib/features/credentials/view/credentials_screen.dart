import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/app/theme/app_gradients.dart';
import 'package:ssi_app/core/utils/navigation_utils.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:ssi_app/services/role/role_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/features/credentials/widgets/credential_form_dialog.dart';
import 'package:ssi_app/features/credentials/models/credential_models.dart';
import 'package:ssi_app/features/credentials/widgets/credential_list_widgets.dart';
import 'package:ssi_app/features/credentials/widgets/credential_details_dialog.dart';

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen>
    with WidgetsBindingObserver {
  final _web3Service = Web3Service();
  final _roleService = RoleService();
  final _pinataService = PinataService();
  final _walletConnectService = WalletConnectService();
  static const List<IconData> _fallbackIcons = [
    Icons.school,
    Icons.workspace_premium,
    Icons.credit_card,
    Icons.car_rental,
    Icons.medical_services,
    Icons.card_membership,
    Icons.verified,
    Icons.badge,
  ];
  List<Map<String, dynamic>> _credentials = [];
  bool _isLoading = true;
  String _address = '';
  Map<String, bool> _canIssueVC = {};
  Map<String, bool> _canRevokeVC = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCredentials();
  }

  @override
  void dispose() {
    // KHÔNG dispose Web3Service ở đây vì nó có thể được dùng ở nhiều nơi
    // Web3Service sẽ tự dispose khi app close hoặc khi không còn cần thiết
    // _web3Service.dispose(); // Commented out to prevent "Client is already closed" errors
    _roleService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadCredentials();
    }
  }

  Future<void> _loadCredentials() async {
    try {
      String? address = await _web3Service.loadWallet();
      address ??= await _walletConnectService.getStoredAddress();

      if (address != null && address.isNotEmpty) {
        final vcs = await _web3Service.getVCs(address);
        final enrichedVcs = await _enrichCredentialsWithMetadata(vcs);

        // Check permissions for each VC's orgID
        final canIssueVC = <String, bool>{};
        final canRevokeVC = <String, bool>{};

        // Extract orgID from VC (we'll use address as orgID for now)
        final orgID = address;
        canIssueVC[orgID] = await _roleService.canIssueVC(orgID, address);
        canRevokeVC[orgID] = await _roleService.canRevokeVC(orgID, address);

        if (!mounted) return;
        setState(() {
          _address = address!;
          _credentials = enrichedVcs;
          _canIssueVC = canIssueVC;
          _canRevokeVC = canRevokeVC;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading credentials: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _enrichCredentialsWithMetadata(
    List<Map<String, dynamic>> vcs,
  ) async {
    if (vcs.isEmpty) {
      return vcs;
    }
    final futures = vcs.map(_hydrateCredentialMetadata).toList();
    return Future.wait(futures);
  }

  Future<Map<String, dynamic>> _hydrateCredentialMetadata(
    Map<String, dynamic> credential,
  ) async {
    final enriched = Map<String, dynamic>.from(credential);
    final uri = credential['uri'] as String?;

    if (uri == null || uri.isEmpty) {
      return enriched;
    }

    try {
      final doc = await _pinataService.getJSON(uri);
      enriched['vcDocument'] = doc;

      final vcType = _extractVcTypeFromDocument(doc);
      if (vcType != null) {
        enriched['vcType'] = vcType;
      }

      final docTitle = _extractTitleFromDocument(doc);
      if (docTitle != null) {
        enriched['title'] = docTitle;
      }

      final attachments = _extractFileAttachments(doc);
      if (attachments.isNotEmpty) {
        enriched['attachments'] = attachments;
      }
    } catch (e) {
      debugPrint('Error hydrating credential metadata for $uri: $e');
    }

    return enriched;
  }

  String? _extractVcTypeFromDocument(Map<String, dynamic> doc) {
    final typeData = doc['type'];
    if (typeData is List) {
      for (final entry in typeData.reversed) {
        final value = entry?.toString();
        if (value != null &&
            value.isNotEmpty &&
            value != 'VerifiableCredential') {
          return value;
        }
      }
    } else if (typeData is String &&
        typeData.isNotEmpty &&
        typeData != 'VerifiableCredential') {
      return typeData;
    }
    return null;
  }

  String? _extractTitleFromDocument(Map<String, dynamic> doc) {
    final directTitle = doc['name'];
    if (directTitle is String && directTitle.trim().isNotEmpty) {
      return directTitle.trim();
    }

    final subject = doc['credentialSubject'];
    if (subject is Map<String, dynamic>) {
      final subjectTitle =
          subject['credentialType'] ??
          subject['credentialName'] ??
          subject['name'] ??
          subject['fullName'];
      if (subjectTitle is String && subjectTitle.trim().isNotEmpty) {
        return subjectTitle.trim();
      }
    }
    return null;
  }

  List<CredentialAttachment> _extractFileAttachments(
    Map<String, dynamic>? doc,
  ) {
    if (doc == null) {
      return const [];
    }
    final subject = doc['credentialSubject'];
    if (subject is! Map<String, dynamic>) {
      return const [];
    }

    final attachments = <CredentialAttachment>[];
    subject.forEach((key, value) {
      if (value is! String || value.isEmpty) {
        return;
      }
      final lowerKey = key.toString().toLowerCase();
      if (!lowerKey.contains('file') && !lowerKey.contains('document')) {
        return;
      }
      if (lowerKey.contains('filename') || lowerKey.contains('file_name')) {
        return;
      }

      final fileNameKeyCandidates = [
        '${key}FileName',
        '${key}Filename',
        '${key}fileName',
        '${key}filename',
      ];
      String? fileName;
      for (final candidate in fileNameKeyCandidates) {
        final candidateValue = subject[candidate];
        if (candidateValue is String && candidateValue.isNotEmpty) {
          fileName = candidateValue;
          break;
        }
      }

      attachments.add(
        CredentialAttachment(
          rawKey: key.toString(),
          label: _formatFieldLabel(key.toString()),
          uri: value,
          fileName: fileName,
        ),
      );
    });

    return attachments;
  }

  /// Format hash/txHash safely, handling short strings
  String _formatHash(String hash, {int prefixLength = 10, int suffixLength = 0}) {
    if (hash.isEmpty) return '';
    if (hash.length <= prefixLength + suffixLength) {
      return hash; // Return as-is if too short
    }
    if (suffixLength == 0) {
      return '${hash.substring(0, prefixLength)}...';
    }
    return '${hash.substring(0, prefixLength)}...${hash.substring(hash.length - suffixLength)}';
  }

  String _formatFieldLabel(String key) {
    if (key.isEmpty) {
      return 'Document';
    }
    final buffer = StringBuffer();
    for (var i = 0; i < key.length; i++) {
      final char = key[i];
      if (i == 0) {
        buffer.write(char.toUpperCase());
        continue;
      }
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (isUpper) {
        buffer.write(' ');
      }
      buffer.write(char);
    }
    return buffer.toString().replaceAll('_', ' ');
  }


  Future<void> _showCredentialDetails(int index) async {
    final credential = _credentials[index];
    Map<String, dynamic>? vcDoc =
        credential['vcDocument'] as Map<String, dynamic>?;
    bool? sigValid;
    try {
      if (vcDoc == null && (credential['uri'] as String?)?.isNotEmpty == true) {
        vcDoc = await _pinataService.getJSON(credential['uri'] as String);
        credential['vcDocument'] = vcDoc;

        final vcType = _extractVcTypeFromDocument(vcDoc);
        if (vcType != null) {
          credential['vcType'] = vcType;
        }
      }
      if (vcDoc != null) {
        // Optional: verify signature if present
        try {
          sigValid = await _web3Service.verifyVCSignature(
            vcDoc,
            expectedIssuer: credential['issuer'] as String?,
          );
        } catch (e) {
          debugPrint('Error verifying VC signature: $e');
          sigValid = null;
        }
      }
    } catch (e) {
      debugPrint('Error getting VC document: $e');
      vcDoc = null;
      sigValid = null;
    }

    // Always extract attachments from vcDocument to ensure proper type
    // Don't rely on stored attachments in credential map as type information may be lost
    List<CredentialAttachment> attachments = <CredentialAttachment>[];
    if (vcDoc != null) {
      attachments = _extractFileAttachments(vcDoc);
      debugPrint(
        'Extracted ${attachments.length} attachments for credential at index $index',
      );
      if (attachments.isNotEmpty) {
        for (final attachment in attachments) {
          debugPrint('  - ${attachment.label}: ${attachment.uri}');
        }
      }
      // Update credential map for future reference
      credential['attachments'] = attachments;
    } else {
      debugPrint(
        'Warning: vcDoc is null, cannot extract attachments for credential at index $index',
      );
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder:
          (context) => CredentialDetailsDialog(
            credential: credential,
            vcDocument: vcDoc,
            signatureValid: sigValid,
            icon: _iconForCredential(credential, index),
            color: _colorForIndex(index),
            title: _titleForCredential(credential, index, context),
            orgID: _address,
            attachments: attachments,
            onViewAttachment:
                attachments.isNotEmpty
                    ? (attachment, dialogContext) {
                      debugPrint(
                        'Preview attachment clicked: ${attachment.label} - ${attachment.uri}',
                      );
                      // Just trigger state update in dialog, don't close it
                    }
                    : null,
            pinataService: _pinataService,
            onCopyHash:
                () => _copyToClipboard(
                  credential['hashCredential'],
                  AppLocalizations.of(context)!.hashCopied,
                ),
            onRevoke:
                credential['valid'] == true && _canRevokeVC[_address] == true
                    ? () {
                      Navigator.pop(context);
                      _revokeCredential(index);
                    }
                    : null,
            onRequestVerification:
                credential['verified'] != true && credential['valid'] == true
                    ? () {
                      Navigator.pop(context);
                      _showVerificationRequestDialog(index);
                    }
                    : null,
            onVerifyCredential:
                credential['verified'] != true && credential['valid'] == true
                    ? () {
                      Navigator.pop(context);
                      _verifyCredential(index);
                    }
                    : null,
          ),
    );
  }

  Future<void> _issueVC(
    String orgID,
    Map<String, dynamic>? credentialData,
  ) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      _showBlockingSpinner('Đang xử lý files và tạo chứng nhận...');

      final data = Map<String, dynamic>.from(credentialData ?? {});
      final vcType = (data.remove('type') as String?) ?? 'Credential';
      final expirationInput = data.remove('expirationDate') as String?;
      final expirationIso =
          (expirationInput != null && expirationInput.isNotEmpty)
              ? expirationInput
              : null;

      // Handle file uploads - upload files to IPFS and replace file paths with IPFS URIs
      final processedData = <String, dynamic>{};
      for (var entry in data.entries) {
        final key = entry.key;
        final value = entry.value;

        // Check if this is a file field (documentFile, etc.)
        if (key.toLowerCase().contains('file') ||
            key.toLowerCase().contains('document')) {
          if (value is String && value.isNotEmpty) {
            try {
              final file = File(value);
              if (await file.exists()) {
                // Upload file to IPFS
                _showBlockingSpinner(
                  'Đang tải lên file: ${file.path.split('/').last}...',
                );
                final fileBytes = await file.readAsBytes();
                final fileName = file.path.split('/').last;
                final ipfsUri = await _pinataService.uploadFile(
                  fileBytes,
                  fileName,
                );

                // Store IPFS URI instead of file path
                processedData[key] = ipfsUri;
                processedData['${key}FileName'] = fileName;
              } else {
                // File doesn't exist, skip it
                debugPrint('File not found: $value');
              }
            } catch (e) {
              debugPrint('Error uploading file $value: $e');
              // Continue without the file if upload fails
            }
          }
        } else {
          // Regular field, keep as is
          processedData[key] = value;
        }
      }

      // Check if using WalletConnect
      final isWC = await _walletConnectService.hasActiveSession();

      if (isWC) {
        _updateSpinnerMessage(
          'Đang ký credential với MetaMask...\n\nVui lòng mở MetaMask wallet và xác nhận signature.\n\nNếu không thấy notification, vui lòng mở MetaMask app thủ công.',
        );
      } else {
        _updateSpinnerMessage(l10n.creatingVCAndUploading);
      }

      final signedVC = await _web3Service.createAndSignVC(
        orgID: orgID,
        claims: processedData,
        vcType: vcType,
        expirationDateIso: expirationIso,
      );

      // Upload VC to IPFS
      if (isWC) {
        _updateSpinnerMessage('Đang tải credential lên IPFS...');
      }
      final ipfsUri = await _pinataService.uploadJSON(signedVC);
      final hashCredential = _pinataService.generateHash(signedVC);

      // Issue VC on blockchain
      int? expirationTimestamp;
      if (expirationIso != null) {
        final parsed = DateTime.tryParse(expirationIso);
        if (parsed != null) {
          expirationTimestamp = parsed.toUtc().millisecondsSinceEpoch ~/ 1000;
        }
      }

      if (isWC) {
        _updateSpinnerMessage(
          'Đang gửi transaction đến MetaMask...\n\nVui lòng mở MetaMask wallet và xác nhận transaction.\n\nNếu không thấy notification, vui lòng mở MetaMask app thủ công.',
        );
      } else {
        _updateSpinnerMessage('Đang đăng ký credential trên blockchain...');
      }

      String? txHash;
      try {
        txHash = await _web3Service.issueVC(
          orgID,
          hashCredential,
          ipfsUri,
          expirationTimestamp: expirationTimestamp,
        );
      } catch (e) {
        // Nếu validation fail, hiển thị error message ngay
        NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
        _spinnerContext = null;
        if (!mounted) return;

        String errorMessage = 'Lỗi khi issue VC: ${e.toString()}';
        if (e.toString().contains('DID không tồn tại')) {
          errorMessage =
              'DID không tồn tại. Vui lòng đăng ký DID trước khi issue VC.';
        } else if (e.toString().contains('không có quyền')) {
          errorMessage =
              'Bạn không có quyền issue VC cho DID này. Chỉ owner hoặc authorized issuer mới có thể issue VC.';
        } else if (e.toString().contains('deactivate')) {
          errorMessage =
              'DID đã bị deactivate. Vui lòng kích hoạt lại DID trước khi issue VC.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Đợi transaction được confirm và kiểm tra status
      if (isWC) {
        _updateSpinnerMessage(
          'Đang đợi transaction được confirm trên blockchain...\n\nVui lòng đợi...',
        );
      } else {
        _updateSpinnerMessage(
          'Đang đợi transaction được confirm trên blockchain...',
        );
      }

      final success = await _web3Service.waitForTransactionReceipt(txHash);

      NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
      _spinnerContext = null;
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.vcIssued(_formatHash(txHash)),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadCredentials();
      } else {
        // Transaction bị revert - hiển thị thông báo chi tiết hơn
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transaction failed: Transaction đã bị revert trên blockchain.\n\nCó thể do:\n- DID chưa được đăng ký\n- Bạn không có quyền issue VC\n- DID đã bị deactivate\n\nHash: ${_formatHash(txHash)}',
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Safely dismiss dialog even if context is invalid
      NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
      _spinnerContext = null;
      
      // Clear pending flags if transaction was rejected
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        _walletConnectService.clearPendingFlags();
      }
      
      if (!mounted) return;

      // Provide more helpful error messages
      String errorMessage = AppLocalizations.of(
        context,
      )!.errorOccurred(e.toString());
      if (e.toString().toLowerCase().contains('timeout')) {
        errorMessage =
            'Request timeout. Vui lòng kiểm tra MetaMask wallet và xác nhận, sau đó thử lại.';
      } else if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        errorMessage = 'Giao dịch đã bị hủy trong ví. Vui lòng thử lại.';
      } else if (e.toString().toLowerCase().contains('session') &&
          e.toString().toLowerCase().contains('disconnected')) {
        errorMessage =
            'WalletConnect session đã bị ngắt kết nối. Vui lòng kết nối lại wallet.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _revokeCredential(int index) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      _showBlockingSpinner(l10n.revokingVC);
      final txHash = await _web3Service.revokeVC(_address, index);
      NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
      _spinnerContext = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.vcRevoked(_formatHash(txHash)),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      _loadCredentials();
    } catch (e) {
      NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
      _spinnerContext = null;
      
      // Clear pending flags if transaction was rejected
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        _walletConnectService.clearPendingFlags();
      }
      
      if (!mounted) return;
      
      String errorMessage = AppLocalizations.of(context)!.errorOccurred(e.toString());
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        errorMessage = 'Hủy credential đã bị hủy trong ví. Vui lòng thử lại.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showVerificationRequestDialog(int index) async {
    final targetVerifierController = TextEditingController();

    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Request Verification',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VC Index: ${_credentials[index]['index']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toàn bộ nội dung credential sẽ được gửi tự động đến cơ quan xác thực.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: targetVerifierController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ cơ quan xác thực *',
                      hintText: '0x... (để trống nếu cho phép bất kỳ verifier nào)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Gửi yêu cầu'),
              ),
            ],
          ),
    );

    if (result == true) {
      await _requestVerification(
        index,
        targetVerifierController.text.trim(),
      );
    }
  }

  Future<void> _requestVerification(
    int index,
    String targetVerifier,
  ) async {
    try {
      final credential = _credentials[index];
      
      // Lấy vcDocument từ credential hoặc load từ IPFS
      Map<String, dynamic>? vcDocument = credential['vcDocument'] as Map<String, dynamic>?;
      
      if (vcDocument == null) {
        // Nếu chưa có vcDocument, thử load từ URI
        final uri = credential['uri'] as String?;
        if (uri != null && uri.isNotEmpty) {
          _showBlockingSpinner('Đang tải thông tin credential...');
          try {
            vcDocument = await _pinataService.getJSON(uri);
          } catch (e) {
            debugPrint('Error loading VC document from URI: $e');
            NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
            _spinnerContext = null;
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Không thể tải thông tin credential: ${e.toString()}'),
                backgroundColor: AppColors.danger,
              ),
            );
            return;
          }
        } else {
          NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
          _spinnerContext = null;
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credential không có thông tin để gửi. Vui lòng kiểm tra lại.'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
      }
      
      // Upload toàn bộ nội dung credential lên IPFS
      _updateSpinnerMessage('Đang tải toàn bộ nội dung credential lên IPFS...');
      final metadataUri = await _pinataService.uploadJSON(vcDocument);
      
      // Gửi yêu cầu xác thực với metadataUri chứa toàn bộ credential
      _updateSpinnerMessage('Đang gửi yêu cầu xác thực đến blockchain...');
      final txHash = await _web3Service.requestVerification(
        _address,
        index,
        targetVerifier.isNotEmpty ? targetVerifier : null,
        metadataUri,
      );
      
      NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
      _spinnerContext = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yêu cầu xác thực đã được gửi thành công!\nHash: ${_formatHash(txHash)}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      _loadCredentials();
    } catch (e) {
      NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
      _spinnerContext = null;
      
      // Clear pending flags if transaction was rejected
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        _walletConnectService.clearPendingFlags();
      }
      
      if (!mounted) return;
      
      String errorMessage = 'Lỗi: ${e.toString()}';
      
      // Handle specific error cases
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        errorMessage = 'Yêu cầu xác thực đã bị hủy trong ví. Vui lòng thử lại.';
      } else if (e.toString().contains('gas limit too high') ||
                 e.toString().contains('16777216') ||
                 e.toString().contains('gas limit quá cao')) {
        errorMessage = 'Gas limit quá cao. '
            'Hệ thống đã tự động điều chỉnh, nhưng ví của bạn có thể đang estimate lại. '
            'Vui lòng thử lại hoặc giảm kích thước metadata nếu có thể.';
      } else if (e.toString().toLowerCase().contains('timeout')) {
        errorMessage = 'Yêu cầu xác thực đã hết thời gian. Vui lòng thử lại.';
      } else if (e.toString().toLowerCase().contains('session') &&
                 e.toString().toLowerCase().contains('disconnected')) {
        errorMessage = 'WalletConnect session đã bị ngắt kết nối. Vui lòng kết nối lại wallet.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _verifyCredential(int index) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Verify Credential',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to verify this credential?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Verify'),
                ),
              ],
            ),
      );

      if (result != true) return;

      _showBlockingSpinner('Đang xác thực credential...');
      final txHash = await _web3Service.verifyCredential(_address, index);
      NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
      _spinnerContext = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credential verified: ${_formatHash(txHash)}'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadCredentials();
    } catch (e) {
      NavigationUtils.safePopDialog(_spinnerContext ?? (mounted ? context : null));
      _spinnerContext = null;
      
      // Clear pending flags if transaction was rejected
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        _walletConnectService.clearPendingFlags();
      }
      
      if (!mounted) return;
      
      String errorMessage = 'Error: ${e.toString()}';
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        errorMessage = 'Xác thực credential đã bị hủy trong ví. Vui lòng thử lại.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showAddCredentialDialog() {
    if (_address.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseConnectWallet),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder:
          (context) => CredentialFormDialog(
            onSubmit: (credentialData) {
              _issueVC(_address, credentialData);
            },
          ),
    );
  }

  BuildContext? _spinnerContext;

  void _showBlockingSpinner([String? message]) {
    final l10n = AppLocalizations.of(context)!;
    final displayMessage = message ?? l10n.processing;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _spinnerContext = context;
        return AlertDialog(
          backgroundColor: AppColors.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.secondary),
              const SizedBox(height: 16),
              Text(
                displayMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              if (displayMessage.contains('MetaMask') ||
                  displayMessage.contains('wallet'))
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Vui lòng mở MetaMask và xác nhận',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _updateSpinnerMessage(String message) {
    if (_spinnerContext != null && Navigator.canPop(_spinnerContext!)) {
      Navigator.of(_spinnerContext!).pop();
      _showBlockingSpinner(message);
    }
  }

  void _copyToClipboard(String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  IconData _iconForCredential(Map<String, dynamic> credential, int index) {
    final vcType = credential['vcType'] as String?;
    final metadata = vcType != null ? credentialTypeMetadata[vcType] : null;
    if (metadata != null) {
      return metadata.icon;
    }
    return _fallbackIcons[index % _fallbackIcons.length];
  }

  Color _colorForIndex(int index) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
      Color(0xFFEC4899),
      Color(0xFF84CC16),
    ];
    return colors[index % colors.length];
  }

  String _titleForCredential(
    Map<String, dynamic> credential,
    int index,
    BuildContext context,
  ) {
    final typeTitle = _displayNameForType(credential['vcType'] as String?);
    if (typeTitle != null) {
      return typeTitle;
    }

    final customTitle = credential['title']?.toString();
    if (customTitle != null && customTitle.trim().isNotEmpty) {
      return customTitle.trim();
    }

    // Fall back to URI file name (if exists)
    final uri = credential['uri']?.toString() ?? '';
    if (uri.isNotEmpty) {
      final segments = uri.split('/');
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        if (lastSegment.isNotEmpty && !lastSegment.startsWith('Qm')) {
          return lastSegment;
        }
      }
    }

    final l10n = AppLocalizations.of(context)!;
    // Final fallback: generic credential name with index to avoid confusion
    return '${l10n.credentials} #${index + 1}';
  }

  String? _displayNameForType(String? vcType) {
    if (vcType == null) {
      return null;
    }
    return credentialTypeMetadata[vcType]?.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.credentials,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  if (_canIssueVC[_address] == true)
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: IconButton(
                        onPressed: _showAddCredentialDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const CredentialLoadingState()
                      : _credentials.isEmpty
                      ? CredentialEmptyState(onAddCredential: _showAddCredentialDialog)
                      : RefreshIndicator(
                        onRefresh: _loadCredentials,
                        color: AppColors.secondary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _credentials.length,
                          itemBuilder: (context, index) {
                            final credential = _credentials[index];
                            return CredentialCard(
                              title: _titleForCredential(
                                credential,
                                index,
                                context,
                              ),
                              issuer:
                                  credential['issuer'] ??
                                  AppLocalizations.of(context)!.unknown,
                              details:
                                  'Hash: ${_formatHash(credential['hashCredential'] ?? '')}',
                              uri: credential['uri'] ?? '',
                              icon: _iconForCredential(credential, index),
                              color: _colorForIndex(index),
                              isValid: credential['valid'] ?? false,
                              isVerified: credential['verified'] ?? false,
                              onTap: () => _showCredentialDetails(index),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _canIssueVC[_address] == true
              ? FloatingActionButton.extended(
                onPressed: _showAddCredentialDialog,
                backgroundColor: AppColors.secondary,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.issueCredential),
              )
              : null,
    );
  }
}