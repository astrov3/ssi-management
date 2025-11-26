import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/app/theme/app_gradients.dart';
import 'package:ssi_app/core/utils/navigation_utils.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:ssi_app/services/role/role_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/services/wallet/wallet_state_manager.dart';
import 'package:ssi_app/features/credentials/widgets/credential_form_dialog.dart';
import 'package:ssi_app/features/credentials/models/credential_models.dart';
import 'package:ssi_app/features/credentials/widgets/credential_list_widgets.dart';
import 'package:ssi_app/features/credentials/widgets/credential_details_dialog.dart';
import 'package:ssi_app/features/qr/display/qr_display_screen.dart';

enum WalletActionStep {
  signature,
  uploading,
  transaction,
  confirming,
}

class WalletActionState {
  const WalletActionState({
    required this.step,
    this.isCompleted = false,
    this.isError = false,
    this.errorMessage,
  });

  final WalletActionStep step;
  final bool isCompleted;
  final bool isError;
  final String? errorMessage;
}

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
  final _walletStateManager = WalletStateManager();
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
  ValueNotifier<WalletActionState>? _walletActionStateNotifier;
  BuildContext? _walletActionSheetContext;
  Future<void>? _ongoingCredentialLoad;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer heavy credential load until after first frame to avoid janking the splash.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCredentials();
    });
  }

  @override
  void dispose() {

    _roleService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _walletActionStateNotifier?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_walletConnectService.isPendingTransactionOrSignature()) {
        _dismissBlockingSpinner();
      }
    }
    if (state == AppLifecycleState.resumed) {
      _loadCredentials();
    }
  }

  Future<void> _loadCredentials() {
    if (_ongoingCredentialLoad != null) {
      return _ongoingCredentialLoad!;
    }
    final future = _loadCredentialsInternal();
    _ongoingCredentialLoad = future;
    future.whenComplete(() {
      if (identical(_ongoingCredentialLoad, future)) {
        _ongoingCredentialLoad = null;
      }
    });
    return future;
  }

  Future<void> _loadCredentialsInternal() async {
    try {
      if (!_isLoading && mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      final walletState = await _walletStateManager.loadWalletState();

      if (walletState != null && walletState.address.isNotEmpty) {
        final address = walletState.address;
        final vcs = walletState.vcs;
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
          _address = address;
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
    WalletActionStep currentWalletStep = WalletActionStep.signature;
    bool isWalletConnectFlow = false;
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

        if (key.toLowerCase().contains('file') ||
            key.toLowerCase().contains('document')) {
          if (value is String && value.isNotEmpty) {
            try {
              final file = File(value);
              if (await file.exists()) {
                _showBlockingSpinner(
                  'Đang tải lên file: ${file.path.split('/').last}...',
                );
                final fileBytes = await file.readAsBytes();
                final fileName = file.path.split('/').last;
                final ipfsUri = await _pinataService.uploadFile(
                  fileBytes,
                  fileName,
                );
                processedData[key] = ipfsUri;
                processedData['${key}FileName'] = fileName;
              } else {
                debugPrint('File not found: $value');
              }
            } catch (e) {
              debugPrint('Error uploading file $value: $e');
            }
          }
        } else {
          processedData[key] = value;
        }
      }

      final isWC = await _walletConnectService.hasActiveSession();
      isWalletConnectFlow = isWC;
      if (!mounted) return;

      if (isWalletConnectFlow) {
        _dismissBlockingSpinner();
        _showWalletActionSheet(currentWalletStep);
      } else {
        _updateSpinnerMessage(l10n.creatingVCAndUploading);
      }

      final signedVC = await _web3Service.createAndSignVC(
        orgID: orgID,
        claims: processedData,
        vcType: vcType,
        expirationDateIso: expirationIso,
      );

      currentWalletStep = WalletActionStep.uploading;
      if (isWalletConnectFlow) {
        _updateWalletActionStep(currentWalletStep);
      } else {
        _updateSpinnerMessage('Đang tải credential lên IPFS...');
      }

      final ipfsUri = await _pinataService.uploadJSON(signedVC);
      final hashCredential = _pinataService.generateHash(signedVC);

      int? expirationTimestamp;
      if (expirationIso != null) {
        final parsed = DateTime.tryParse(expirationIso);
        if (parsed != null) {
          expirationTimestamp = parsed.toUtc().millisecondsSinceEpoch ~/ 1000;
        }
      }

      currentWalletStep = WalletActionStep.transaction;
      if (isWalletConnectFlow) {
        _updateWalletActionStep(currentWalletStep);
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
        _dismissBlockingSpinner();
        if (isWalletConnectFlow) {
          _setWalletActionError(currentWalletStep, e.toString());
        }
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

      currentWalletStep = WalletActionStep.confirming;
      if (isWalletConnectFlow) {
        _updateWalletActionStep(currentWalletStep);
      } else {
        _updateSpinnerMessage(
          'Đang đợi transaction được confirm trên blockchain...',
        );
      }

      final success = await _web3Service.waitForTransactionReceipt(txHash);

      _dismissBlockingSpinner();
      if (!mounted) return;

      if (success) {
        if (isWalletConnectFlow) {
          _updateWalletActionStep(currentWalletStep, completed: true);
        }
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
        if (isWalletConnectFlow) {
          _setWalletActionError(
            WalletActionStep.transaction,
            'Transaction đã bị revert trên blockchain.',
          );
        }
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
      _dismissBlockingSpinner();

      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        _walletConnectService.clearPendingFlags();
      }

      if (!mounted) {
        if (isWalletConnectFlow) {
          _setWalletActionError(currentWalletStep, e.toString());
        }
        return;
      }

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

      if (isWalletConnectFlow) {
        _setWalletActionError(currentWalletStep, errorMessage);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (isWalletConnectFlow) {
        await Future.delayed(const Duration(milliseconds: 400));
        await _hideWalletActionSheet();
      }
    }
  }

  void _showWalletActionSheet(WalletActionStep initialStep) {
    if (!mounted) return;
    _walletActionStateNotifier?.dispose();
    _walletActionStateNotifier = ValueNotifier(
      WalletActionState(step: initialStep),
    );
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        _walletActionSheetContext = sheetContext;
        return _WalletActionSheet(
          stateListenable: _walletActionStateNotifier!,
          onOpenWallet: () => _walletConnectService.openWalletApp(),
        );
      },
    ).whenComplete(() {
      _walletActionSheetContext = null;
      _walletActionStateNotifier?.dispose();
      _walletActionStateNotifier = null;
    });
  }

  void _updateWalletActionStep(
    WalletActionStep step, {
    bool completed = false,
  }) {
    final notifier = _walletActionStateNotifier;
    if (notifier == null) return;
    notifier.value = WalletActionState(
      step: step,
      isCompleted: completed,
    );
  }

  void _setWalletActionError(WalletActionStep step, String message) {
    final notifier = _walletActionStateNotifier;
    if (notifier == null) return;
    notifier.value = WalletActionState(
      step: step,
      isError: true,
      errorMessage: message,
    );
  }

  Future<void> _hideWalletActionSheet() async {
    final sheetContext = _walletActionSheetContext;
    if (sheetContext == null) {
      return;
    }
    if (Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
    } else {
      Navigator.of(sheetContext).maybePop();
    }
  }

  Future<void> _revokeCredential(int index) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      _showBlockingSpinner(l10n.revokingVC);
      final txHash = await _web3Service.revokeVC(_address, index);
      _dismissBlockingSpinner();
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
      _dismissBlockingSpinner();
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
          _showBlockingSpinner('Loading credential information...');
          try {
            vcDocument = await _pinataService.getJSON(uri);
          } catch (e) {
            debugPrint('Error loading VC document from URI: $e');
            _dismissBlockingSpinner();
            _spinnerContext = null;
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unable to load credential information: ${e.toString()}'),
                backgroundColor: AppColors.danger,
              ),
            );
            return;
          }
        } else {
          _dismissBlockingSpinner();
          _spinnerContext = null;
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credential has no information to send. Please check again.'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
      }
      
      // Upload the full credential content to IPFS
      _updateSpinnerMessage('Uploading full credential content to IPFS...');
      final metadataUri = await _pinataService.uploadJSON(vcDocument);
      
      // Send verification request with metadataUri containing the full credential
      _updateSpinnerMessage('Sending verification request to blockchain...');
      final txHash = await _web3Service.requestVerification(
        _address,
        index,
        targetVerifier.isNotEmpty ? targetVerifier : null,
        metadataUri,
      );
      
      _dismissBlockingSpinner();
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
      _dismissBlockingSpinner();
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
      _dismissBlockingSpinner();
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
      _dismissBlockingSpinner();
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
  bool _isSpinnerVisible = false;

  void _showBlockingSpinner([String? message]) {
    final l10n = AppLocalizations.of(context)!;
    final displayMessage = message ?? l10n.processing;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _spinnerContext = dialogContext;
        _isSpinnerVisible = true;
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
              if (displayMessage.toLowerCase().contains('metamask') ||
                  displayMessage.toLowerCase().contains('wallet'))
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Vui lòng mở ví của bạn và xác nhận',
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
    if (!_isSpinnerVisible || _spinnerContext == null) {
      return;
    }
    if (Navigator.canPop(_spinnerContext!)) {
      Navigator.of(_spinnerContext!).pop();
      _showBlockingSpinner(message);
    }
  }

  void _dismissBlockingSpinner() {
    if (_spinnerContext != null) {
      NavigationUtils.safePopDialog(_spinnerContext);
      _spinnerContext = null;
    }
    _isSpinnerVisible = false;
  }

  void _copyToClipboard(String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showCredentialQrDialog(int index) {
    final credential = _credentials[index];
    final qrPayload = {
      'type': 'VC',
      'orgID': _address,
      'index': credential['index'],
      'hashCredential': credential['hashCredential'],
      'uri': credential['uri'],
      'issuer': credential['issuer'],
    };
    final qrString = jsonEncode(qrPayload);
    final credentialTitle = _titleForCredential(credential, index, context);
    final isVerified = credential['verified'] == true;
    final isValid = credential['valid'] != false;

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '${l10n.myQrCode} - $credentialTitle',
            style: TextStyle(color: Colors.grey[900]),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: qrString,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isValid ? AppColors.success : AppColors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isValid ? l10n.valid : l10n.revoked,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isVerified ? AppColors.success : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isVerified ? 'Verified' : 'Unverified',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QRDisplayScreen(qrData: qrPayload),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Xem chi tiết'),
            ),
          ],
        );
      },
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
    final l10n = AppLocalizations.of(context)!;
    final typeTitle = _displayNameForType(credential['vcType'] as String?, l10n);
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

    // Final fallback: generic credential name with index to avoid confusion
    return '${l10n.credentials} #${index + 1}';
  }

  String? _displayNameForType(String? vcType, AppLocalizations l10n) {
    return CredentialTypeMetadata.getLocalizedTitle(vcType, l10n);
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
                              onShareQr: () => _showCredentialQrDialog(index),
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

const List<_WalletStepDescriptor> _walletStepDescriptors = [
  _WalletStepDescriptor(
    step: WalletActionStep.signature,
    title: 'Ký credential',
    subtitle: 'Xác nhận chữ ký EIP-712 trong ví của bạn.',
  ),
  _WalletStepDescriptor(
    step: WalletActionStep.uploading,
    title: 'Upload credential',
    subtitle: 'Ứng dụng tự động tải dữ liệu lên IPFS.',
  ),
  _WalletStepDescriptor(
    step: WalletActionStep.transaction,
    title: 'Ký giao dịch',
    subtitle: 'Chấp nhận transaction issue VC trong ví của bạn.',
  ),
  _WalletStepDescriptor(
    step: WalletActionStep.confirming,
    title: 'Chờ blockchain xác nhận',
    subtitle: 'Giữ ứng dụng mở trong lúc chờ xác nhận on-chain.',
  ),
];

class _WalletActionSheet extends StatelessWidget {
  const _WalletActionSheet({
    required this.stateListenable,
    required this.onOpenWallet,
  });

  final ValueListenable<WalletActionState> stateListenable;
  final Future<void> Function() onOpenWallet;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  // Cho phép nội dung cao hơn viewport và scroll được
                  maxHeight: constraints.maxHeight,
                ),
                child: ValueListenableBuilder<WalletActionState>(
                  valueListenable: stateListenable,
                  builder: (context, state, _) {
                    final int activeIndex = _walletStepDescriptors.indexWhere(
                      (descriptor) => descriptor.step == state.step,
                    );
                    final bool showWalletButton = !state.isCompleted &&
                        !state.isError &&
                        (state.step == WalletActionStep.signature ||
                            state.step == WalletActionStep.transaction);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Text(
                          'Xác nhận trong ví',
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Giữ ứng dụng này mở và chuyển sang ví khi được yêu cầu.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ..._walletStepDescriptors.asMap().entries.map(
                          (entry) {
                            final descriptor = entry.value;
                            final descriptorIndex = entry.key;
                            final bool isCurrent = descriptorIndex == activeIndex &&
                                !state.isCompleted &&
                                !state.isError;
                            final bool isCompleted = descriptorIndex < activeIndex ||
                                (state.isCompleted && descriptor.step == state.step);
                            final bool showError =
                                state.isError && descriptor.step == state.step;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _WalletActionStepRow(
                                descriptor: descriptor,
                                isActive: isCurrent,
                                isCompleted: isCompleted,
                                showError: showError,
                              ),
                            );
                          },
                        ),
                        if (showWalletButton) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onOpenWallet,
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Mở ví'),
                            ),
                          ),
                        ],
                        if (state.isCompleted) ...[
                          const SizedBox(height: 12),
                          const _WalletActionInfoBanner(
                            icon: Icons.check_circle,
                            color: AppColors.success,
                            message: 'Đã hoàn tất. Bạn có thể quay lại ứng dụng.',
                          ),
                        ],
                        if (state.isError && state.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          _WalletActionInfoBanner(
                            icon: Icons.error_outline,
                            color: AppColors.danger,
                            message: state.errorMessage!,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WalletStepDescriptor {
  const _WalletStepDescriptor({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final WalletActionStep step;
  final String title;
  final String subtitle;
}

class _WalletActionStepRow extends StatelessWidget {
  const _WalletActionStepRow({
    required this.descriptor,
    required this.isActive,
    required this.isCompleted,
    required this.showError,
  });

  final _WalletStepDescriptor descriptor;
  final bool isActive;
  final bool isCompleted;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    Widget indicator;
    Color borderColor = Colors.grey[200]!;

    if (showError) {
      indicator = const Icon(Icons.error_outline, color: AppColors.danger, size: 20);
      borderColor = AppColors.danger.withValues(alpha: 0.2);
    } else if (isCompleted) {
      indicator = const Icon(Icons.check_circle, color: AppColors.success, size: 20);
      borderColor = AppColors.success.withValues(alpha: 0.2);
    } else if (isActive) {
      indicator = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
        ),
      );
      borderColor = AppColors.secondary.withValues(alpha: 0.2);
    } else {
      indicator = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: indicator,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descriptor.title,
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descriptor.subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletActionInfoBanner extends StatelessWidget {
  const _WalletActionInfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}