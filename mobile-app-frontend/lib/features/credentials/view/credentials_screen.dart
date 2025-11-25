import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/app/theme/app_gradients.dart';
import 'package:ssi_app/core/widgets/glass_container.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:ssi_app/services/role/role_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/widgets/credential_form_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class _CredentialTypeMetadata {
  final String title;
  final IconData icon;

  const _CredentialTypeMetadata({required this.title, required this.icon});
}

class _CredentialAttachment {
  final String rawKey;
  final String label;
  final String uri;
  final String? fileName;

  const _CredentialAttachment({
    required this.rawKey,
    required this.label,
    required this.uri,
    this.fileName,
  });
}

class _GatewayLink {
  final String label;
  final String url;

  const _GatewayLink({required this.label, required this.url});
}

const Map<String, _CredentialTypeMetadata> _credentialTypeMetadata = {
  'IdentityCredential': _CredentialTypeMetadata(
    title: 'Government ID',
    icon: Icons.credit_card,
  ),
  'PassportCredential': _CredentialTypeMetadata(
    title: 'Passport',
    icon: Icons.article,
  ),
  'DriverLicenseCredential': _CredentialTypeMetadata(
    title: 'Driver License',
    icon: Icons.drive_eta,
  ),
  'EducationalCredential': _CredentialTypeMetadata(
    title: 'University Degree',
    icon: Icons.school,
  ),
  'ProfessionalCredential': _CredentialTypeMetadata(
    title: 'Professional Certificate',
    icon: Icons.workspace_premium,
  ),
  'TrainingCredential': _CredentialTypeMetadata(
    title: 'Training Certificate',
    icon: Icons.book,
  ),
  'EmploymentCredential': _CredentialTypeMetadata(
    title: 'Employment Credential',
    icon: Icons.business_center,
  ),
  'WorkPermitCredential': _CredentialTypeMetadata(
    title: 'Work Permit',
    icon: Icons.work,
  ),
  'HealthInsuranceCredential': _CredentialTypeMetadata(
    title: 'Health Insurance',
    icon: Icons.medical_services,
  ),
  'VaccinationCredential': _CredentialTypeMetadata(
    title: 'Vaccination Certificate',
    icon: Icons.vaccines,
  ),
  'MembershipCredential': _CredentialTypeMetadata(
    title: 'Membership Card',
    icon: Icons.card_membership,
  ),
  'Credential': _CredentialTypeMetadata(
    title: 'Credential',
    icon: Icons.verified,
  ),
};

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

  List<_CredentialAttachment> _extractFileAttachments(
    Map<String, dynamic>? doc,
  ) {
    if (doc == null) {
      return const [];
    }
    final subject = doc['credentialSubject'];
    if (subject is! Map<String, dynamic>) {
      return const [];
    }

    final attachments = <_CredentialAttachment>[];
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
        _CredentialAttachment(
          rawKey: key.toString(),
          label: _formatFieldLabel(key.toString()),
          uri: value,
          fileName: fileName,
        ),
      );
    });

    return attachments;
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

  List<_GatewayLink> _buildGatewayLinks(String uri) {
    final links = <_GatewayLink>[];
    final defaultUrl = _pinataService.resolveToHttp(uri);
    if (defaultUrl.isNotEmpty) {
      links.add(_GatewayLink(label: 'Pinata', url: defaultUrl));
    }

    final hash = _extractIpfsHash(uri);
    if (hash != null && hash.isNotEmpty) {
      final ipfsIo = 'https://ipfs.io/ipfs/$hash';
      if (!links.any((link) => link.url == ipfsIo)) {
        links.add(_GatewayLink(label: 'ipfs.io', url: ipfsIo));
      }

      final dwebLink = 'https://dweb.link/ipfs/$hash';
      if (!links.any((link) => link.url == dwebLink)) {
        links.add(_GatewayLink(label: 'dweb.link', url: dwebLink));
      }
    }

    return links;
  }

  String? _extractIpfsHash(String uri) {
    if (uri.isEmpty) {
      return null;
    }
    if (uri.startsWith('ipfs://')) {
      return uri.replaceFirst('ipfs://', '');
    }
    final ipfsIndex = uri.indexOf('/ipfs/');
    if (ipfsIndex != -1) {
      final hash = uri.substring(ipfsIndex + 6);
      return hash.split('?').first;
    }
    final segments = uri.split('/');
    if (segments.isNotEmpty) {
      return segments.last.split('?').first;
    }
    return null;
  }

  void _showFilePreview(_CredentialAttachment attachment) {
    debugPrint('_showFilePreview called for: ${attachment.uri}');
    final gateways = _buildGatewayLinks(attachment.uri);
    debugPrint('Built ${gateways.length} gateway links');
    if (gateways.isEmpty) {
      debugPrint('No gateways found, opening external link');
      _openExternalLink(_pinataService.resolveToHttp(attachment.uri));
      return;
    }

    var selectedLink = gateways.first;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isImage = _isImageUrl(selectedLink.url);
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 600,
                  maxWidth: 460,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              attachment.fileName ?? attachment.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton<_GatewayLink>(
                            initialValue: selectedLink,
                            icon: const Icon(Icons.link, color: Colors.white70),
                            onSelected: (link) {
                              setState(() {
                                selectedLink = link;
                              });
                            },
                            itemBuilder:
                                (context) =>
                                    gateways
                                        .map(
                                          (link) => PopupMenuItem<_GatewayLink>(
                                            value: link,
                                            child: Text(link.label),
                                          ),
                                        )
                                        .toList(),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.open_in_new,
                              color: Colors.white70,
                            ),
                            onPressed:
                                () => _openExternalLink(selectedLink.url),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 360,
                        child:
                            isImage
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: InteractiveViewer(
                                    child: Image.network(
                                      selectedLink.url,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        progress,
                                      ) {
                                        if (progress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                progress.expectedTotalBytes !=
                                                        null
                                                    ? progress
                                                            .cumulativeBytesLoaded /
                                                        (progress
                                                                .expectedTotalBytes ??
                                                            1)
                                                    : null,
                                            color: AppColors.secondary,
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return _AttachmentPreviewFallback(
                                          url: selectedLink.url,
                                          onOpenExternal:
                                              () => _openExternalLink(
                                                selectedLink.url,
                                              ),
                                        );
                                      },
                                    ),
                                  ),
                                )
                                : _AttachmentPreviewFallback(
                                  url: selectedLink.url,
                                  onOpenExternal:
                                      () => _openExternalLink(selectedLink.url),
                                ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Gateway',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            gateways
                                .map(
                                  (link) => ChoiceChip(
                                    label: Text(
                                      link.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    selected: selectedLink.url == link.url,
                                    onSelected:
                                        (_) =>
                                            setState(() => selectedLink = link),
                                    selectedColor: AppColors.secondary
                                        .withValues(alpha: 0.3),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.05,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.webp');
  }

  Future<void> _openExternalLink(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw 'Không thể mở liên kết';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở file: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
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
    List<_CredentialAttachment> attachments = <_CredentialAttachment>[];
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
          (context) => _CredentialDetailsDialog(
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
                      // Close credential details dialog first, then show preview
                      Navigator.of(dialogContext).pop();
                      // Use a post-frame callback to ensure dialog is closed before showing preview
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _showFilePreview(attachment);
                        }
                      });
                    }
                    : null,
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
    final navigator = Navigator.of(context);
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
        navigator.pop();
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

      navigator.pop();
      _spinnerContext = null;
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.vcIssued('${txHash.substring(0, 10)}...'),
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
              'Transaction failed: Transaction đã bị revert trên blockchain.\n\nCó thể do:\n- DID chưa được đăng ký\n- Bạn không có quyền issue VC\n- DID đã bị deactivate\n\nHash: ${txHash.substring(0, 10)}...',
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      navigator.pop();
      _spinnerContext = null;
      if (!mounted) return;

      // Provide more helpful error messages
      String errorMessage = AppLocalizations.of(
        context,
      )!.errorOccurred(e.toString());
      if (e.toString().contains('timeout')) {
        errorMessage =
            'Request timeout. Vui lòng kiểm tra MetaMask wallet và xác nhận, sau đó thử lại.';
      } else if (e.toString().contains('rejected') ||
          e.toString().contains('denied')) {
        errorMessage = 'Request đã bị từ chối trong MetaMask wallet.';
      } else if (e.toString().contains('session') &&
          e.toString().contains('disconnected')) {
        errorMessage =
            'WalletConnect session đã bị ngắt kết nối. Vui lòng kết nối lại wallet.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _revokeCredential(int index) async {
    final navigator = Navigator.of(context);
    try {
      final l10n = AppLocalizations.of(context)!;
      _showBlockingSpinner(l10n.revokingVC);
      final txHash = await _web3Service.revokeVC(_address, index);
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.vcRevoked('${txHash.substring(0, 10)}...'),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      _loadCredentials();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorOccurred(e.toString()),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _showVerificationRequestDialog(int index) async {
    final metadataUriController = TextEditingController();
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: metadataUriController,
                    decoration: const InputDecoration(
                      labelText: 'Metadata URI (IPFS) *',
                      hintText: 'ipfs://Qm...',
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: targetVerifierController,
                    decoration: const InputDecoration(
                      labelText: 'Target Verifier (Optional)',
                      hintText: 'Leave empty for any verifier',
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
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Request'),
              ),
            ],
          ),
    );

    if (result == true && metadataUriController.text.isNotEmpty) {
      await _requestVerification(
        index,
        metadataUriController.text.trim(),
        targetVerifierController.text.trim(),
      );
    }
  }

  Future<void> _requestVerification(
    int index,
    String metadataUri,
    String targetVerifier,
  ) async {
    final navigator = Navigator.of(context);
    try {
      _showBlockingSpinner('Đang tạo yêu cầu xác thực...');
      final txHash = await _web3Service.requestVerification(
        _address,
        index,
        targetVerifier.isNotEmpty ? targetVerifier : null,
        metadataUri,
      );
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification request created: ${txHash.substring(0, 10)}...',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _loadCredentials();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _verifyCredential(int index) async {
    final navigator = Navigator.of(context);
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
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credential verified: ${txHash.substring(0, 10)}...'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadCredentials();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.danger,
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
    final metadata = vcType != null ? _credentialTypeMetadata[vcType] : null;
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
    return _credentialTypeMetadata[vcType]?.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                      ? const _LoadingState()
                      : _credentials.isEmpty
                      ? _EmptyState(onAddCredential: _showAddCredentialDialog)
                      : RefreshIndicator(
                        onRefresh: _loadCredentials,
                        color: AppColors.secondary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _credentials.length,
                          itemBuilder: (context, index) {
                            final credential = _credentials[index];
                            return _CredentialCard(
                              title: _titleForCredential(
                                credential,
                                index,
                                context,
                              ),
                              issuer:
                                  credential['issuer'] ??
                                  AppLocalizations.of(context)!.unknown,
                              details:
                                  'Hash: ${credential['hashCredential'].substring(0, 10)}...',
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.loadingCredentials,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onAddCredential});

  final VoidCallback? onAddCredential;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noCredentials,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.pressAddToAddCredential,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
          if (onAddCredential != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddCredential,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(AppLocalizations.of(context)!.issueCredential),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({
    required this.title,
    required this.issuer,
    required this.details,
    required this.uri,
    required this.icon,
    required this.color,
    required this.isValid,
    required this.isVerified,
    required this.onTap,
  });

  final String title;
  final String issuer;
  final String details;
  final String uri;
  final IconData icon;
  final Color color;
  final bool isValid;
  final bool isVerified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          borderColor:
              isValid
                  ? color.withValues(alpha: 0.3)
                  : AppColors.danger.withValues(alpha: 0.3),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (isValid
                                        ? AppColors.success
                                        : AppColors.danger)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isValid
                                    ? AppLocalizations.of(context)!.valid
                                    : AppLocalizations.of(context)!.revoked,
                                style: TextStyle(
                                  color:
                                      isValid
                                          ? AppColors.success
                                          : AppColors.danger,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: AppColors.success,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppLocalizations.of(context)!.issuer}: ${issuer.substring(0, 10)}...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredentialDetailsDialog extends StatelessWidget {
  const _CredentialDetailsDialog({
    required this.credential,
    required this.vcDocument,
    required this.signatureValid,
    required this.icon,
    required this.color,
    required this.title,
    required this.orgID,
    required this.onCopyHash,
    required this.attachments,
    this.onRevoke,
    this.onRequestVerification,
    this.onVerifyCredential,
    this.onViewAttachment,
  });

  final Map<String, dynamic> credential;
  final Map<String, dynamic>? vcDocument;
  final bool? signatureValid;
  final IconData icon;
  final Color color;
  final String title;
  final String orgID;
  final VoidCallback onCopyHash;
  final List<_CredentialAttachment> attachments;
  final VoidCallback? onRevoke;
  final VoidCallback? onRequestVerification;
  final VoidCallback? onVerifyCredential;
  final void Function(
    _CredentialAttachment attachment,
    BuildContext dialogContext,
  )?
  onViewAttachment;

  @override
  Widget build(BuildContext context) {
    bool isAttachmentKey(String key) {
      for (final attachment in attachments) {
        if (attachment.rawKey == key) {
          return true;
        }
        final candidates = [
          '${attachment.rawKey}FileName',
          '${attachment.rawKey}Filename',
          '${attachment.rawKey}fileName',
          '${attachment.rawKey}filename',
        ];
        if (candidates.contains(key)) {
          return true;
        }
      }
      return false;
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (credential['valid']
                                        ? AppColors.success
                                        : AppColors.danger)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                credential['valid']
                                    ? AppLocalizations.of(context)!.valid
                                    : AppLocalizations.of(context)!.revoked,
                                style: TextStyle(
                                  color:
                                      credential['valid']
                                          ? AppColors.success
                                          : AppColors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (credential['verified'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: AppColors.success,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(
                label: AppLocalizations.of(context)!.index,
                value: credential['index'].toString(),
              ),
              _DetailRow(
                label: AppLocalizations.of(context)!.issuer,
                value: credential['issuer'],
              ),
              _DetailRow(
                label: AppLocalizations.of(context)!.credentialHash,
                value: credential['hashCredential'],
              ),
              _DetailRow(label: 'URI', value: credential['uri']),
              if (credential['issuedAt'] != null)
                _DetailRow(
                  label: 'Issued At',
                  value:
                      DateTime.fromMillisecondsSinceEpoch(
                        (credential['issuedAt'] as int) * 1000,
                      ).toIso8601String(),
                ),
              if (credential['expirationDate'] != null &&
                  (credential['expirationDate'] as int) > 0)
                _DetailRow(
                  label: 'Expiration',
                  value:
                      DateTime.fromMillisecondsSinceEpoch(
                        (credential['expirationDate'] as int) * 1000,
                      ).toIso8601String(),
                ),
              if (credential['verified'] == true) ...[
                if (credential['verifier'] != null)
                  _DetailRow(
                    label: 'Verified By',
                    value: credential['verifier'],
                  ),
                if (credential['verifiedAt'] != null &&
                    (credential['verifiedAt'] as int) > 0)
                  _DetailRow(
                    label: 'Verified At',
                    value:
                        DateTime.fromMillisecondsSinceEpoch(
                          (credential['verifiedAt'] as int) * 1000,
                        ).toIso8601String(),
                  ),
              ],
              if (vcDocument != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Type',
                  value:
                      (vcDocument!['type'] as List?)?.join(', ') ??
                      'VerifiableCredential',
                ),
                _DetailRow(
                  label: 'Subject',
                  value:
                      (vcDocument!['credentialSubject'] as Map?)?['id']
                          ?.toString() ??
                      '',
                ),
                if ((vcDocument!['credentialSubject'] as Map?) != null)
                  ...((vcDocument!['credentialSubject'] as Map).entries
                      .where(
                        (e) =>
                            e.key != 'id' && !isAttachmentKey(e.key.toString()),
                      )
                      .map(
                        (e) => _DetailRow(
                          label: e.key.toString(),
                          value: e.value.toString(),
                        ),
                      )),
                if (signatureValid != null)
                  _DetailRow(
                    label: 'Signature',
                    value: signatureValid! ? 'Valid' : 'Invalid',
                  ),
              ],
              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Files',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (dialogContext) {
                    debugPrint(
                      'Rendering ${attachments.length} attachment rows',
                    );
                    debugPrint(
                      'onViewAttachment is ${onViewAttachment != null ? "not null" : "null"}',
                    );
                    return Column(
                      children:
                          attachments.map((attachment) {
                            debugPrint(
                              'Rendering attachment row: ${attachment.label}',
                            );
                            return _AttachmentRow(
                              attachment: attachment,
                              onView:
                                  onViewAttachment != null
                                      ? () {
                                        debugPrint(
                                          'Attachment row clicked: ${attachment.label}',
                                        );
                                        onViewAttachment!(
                                          attachment,
                                          dialogContext,
                                        );
                                      }
                                      : null,
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onCopyHash,
                      icon: const Icon(Icons.copy),
                      label: Text(AppLocalizations.of(context)!.copyHash),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (onRequestVerification != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRequestVerification,
                        icon: const Icon(Icons.send),
                        label: const Text('Request Verification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  if (onVerifyCredential != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onVerifyCredential,
                        icon: const Icon(Icons.verified),
                        label: const Text('Verify'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  if (onRevoke != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRevoke,
                        icon: const Icon(Icons.block),
                        label: Text(AppLocalizations.of(context)!.revoke),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'Courier',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreviewFallback extends StatelessWidget {
  const _AttachmentPreviewFallback({
    required this.url,
    required this.onOpenExternal,
  });

  final String url;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.insert_drive_file,
          size: 48,
          color: Colors.white.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 12),
        Text(
          'Không thể preview file này',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Vui lòng thử mở bằng gateway khác hoặc trình duyệt.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          url,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onOpenExternal,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Mở trong trình duyệt'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
        ),
      ],
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment, this.onView});

  final _CredentialAttachment attachment;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final subtitle = attachment.fileName ?? attachment.label;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.insert_drive_file,
              color: Colors.white70,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onView,
            icon: const Icon(Icons.visibility, color: Colors.white70),
            tooltip: 'Xem file',
          ),
        ],
      ),
    );
  }
}
