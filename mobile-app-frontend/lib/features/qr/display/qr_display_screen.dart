import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/features/credentials/models/credential_models.dart';
import 'package:ssi_app/features/credentials/widgets/credential_detail_widgets.dart';
import 'package:ssi_app/features/credentials/widgets/fullscreen_image_viewer.dart';
import 'package:ssi_app/features/credentials/widgets/fullscreen_pdf_viewer.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:url_launcher/url_launcher.dart';

class QRDisplayScreen extends StatefulWidget {
  const QRDisplayScreen({
    super.key,
    required this.qrData,
  });

  final Map<String, dynamic> qrData;

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  final _web3Service = Web3Service();
  final _pinataService = PinataService();
  bool _isLoading = true;
  Map<String, dynamic>? _fullData;
  bool? _signatureValid;
  bool? _onChainValid;
  String? _error;
  CredentialAttachment? _previewingAttachment;
  GatewayLink? _selectedGatewayLink;

  @override
  void initState() {
    super.initState();
    _loadFullData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFullData() async {
    try {
      final type = widget.qrData['type'] as String?;
      
      if (type == 'VC') {
        await _loadVCData();
      } else if (type == 'DID') {
        await _loadDIDData();
      } else if (type == 'VERIFICATION_REQUEST') {
        await _verifyRequest();
      } else {
        setState(() {
          _error = 'Unknown QR code type';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVCData() async {
    try {
      final orgID = widget.qrData['orgID'] as String?;
      final uri = widget.qrData['uri'] as String?;
      final hashCredential = widget.qrData['hashCredential'] as String?;

      if (uri == null || uri.isEmpty) {
        setState(() {
          _error = 'VC URI not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch VC document from IPFS
      final vcDoc = await _pinataService.getJSON(uri);
      
      // Verify signature if proof exists
      bool? sigValid;
      if (vcDoc['proof'] != null) {
        try {
          // Use issuer from QR payload (on-chain issuer) when available,
          // otherwise let Web3Service infer from VC issuer (handles did:ethr:...)
          final qrIssuer = widget.qrData['issuer'] as String?;
          sigValid = await _web3Service.verifyVCSignature(
            vcDoc,
            expectedIssuer: qrIssuer,
          );
        } catch (_) {
          sigValid = null;
        }
      }

      // Verify on-chain if we have orgID and hash
      bool? onChainValid;
      if (orgID != null && hashCredential != null) {
        try {
          // Try to get VC index from QR data or find it
          final index = widget.qrData['index'] as int?;
          if (index != null) {
            onChainValid = await _web3Service.verifyVC(orgID, index, hashCredential);
          }
        } catch (_) {
          onChainValid = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _fullData = vcDoc;
        _signatureValid = sigValid;
        _onChainValid = onChainValid;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load VC: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDIDData() async {
    try {
      final uri = widget.qrData['uri'] as String?;

      if (uri == null || uri.isEmpty) {
        setState(() {
          _error = 'DID URI not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch DID document from IPFS
      final didDoc = await _pinataService.getJSON(uri);

      if (!mounted) return;
      setState(() {
        _fullData = didDoc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load DID: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyRequest() async {
    try {
      final orgID = widget.qrData['orgID'] as String?;
      final vcIndex = widget.qrData['vcIndex'] as int?;

      if (orgID == null || vcIndex == null) {
        setState(() {
          _error = 'Invalid verification request';
          _isLoading = false;
        });
        return;
      }

      // Get VC data from blockchain
      final vc = await _web3Service.getVC(orgID, vcIndex);
      final hash = vc['hashCredential'] as String?;
      final uri = vc['uri'] as String?;

      if (hash == null) {
        setState(() {
          _error = 'VC not found';
          _isLoading = false;
        });
        return;
      }

      // Verify on-chain
      final isValid = await _web3Service.verifyVC(orgID, vcIndex, hash);

      // Fetch VC document if URI exists
      Map<String, dynamic>? vcDoc;
      bool? sigValid;
      if (uri != null && uri.isNotEmpty) {
        try {
          vcDoc = await _pinataService.getJSON(uri);
          if (vcDoc['proof'] != null) {
            final issuer = vcDoc['issuer'] as String?;
            if (issuer != null) {
              sigValid = await _web3Service.verifyVCSignature(vcDoc, expectedIssuer: issuer);
            }
          }
        } catch (_) {
          // Ignore IPFS fetch errors
        }
      }

      if (!mounted) return;
      setState(() {
        _fullData = {...vc, if (vcDoc != null) 'document': vcDoc};
        _onChainValid = isValid;
        _signatureValid = sigValid;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to verify: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = timestamp is int
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : DateTime.parse(timestamp.toString());
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    } catch (_) {
      return timestamp.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = widget.qrData['type'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[900]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          type == 'VC' 
              ? (l10n.verifiableCredential.isNotEmpty ? l10n.verifiableCredential : 'Verifiable Credential')
              : type == 'DID' 
                  ? 'DID Document' 
                  : l10n.verification,
          style: TextStyle(color: Colors.grey[900]),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                          ),
                          child: Text(l10n.close),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (type == 'VC') _buildVCDisplay(l10n),
                        if (type == 'DID') _buildDIDDisplay(l10n),
                        if (type == 'VERIFICATION_REQUEST') _buildVerificationDisplay(l10n),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildVCDisplay(AppLocalizations l10n) {
    final vcDoc = _fullData;
    if (vcDoc == null) {
      return const SizedBox.shrink();
    }

    final credentialSubject =
        vcDoc['credentialSubject'] as Map<String, dynamic>? ?? {};
    final type = (vcDoc['type'] as List?)?.join(', ') ?? 'VerifiableCredential';
    final issuer = vcDoc['issuer'] as String? ?? '';
    final issuanceDate = vcDoc['issuanceDate'] as String?;
    final expirationDate = vcDoc['expirationDate'] as String?;
    final id = vcDoc['id'] as String?;

    // Extract attachments and filter them out from subject fields
    final attachments = _extractFileAttachments(vcDoc);
    final attachmentKeys = attachments.map((a) => a.rawKey).toSet();
    final attachmentFileNameKeys = attachments
        .map(
          (a) => [
            '${a.rawKey}FileName',
            '${a.rawKey}Filename',
            '${a.rawKey}fileName',
            '${a.rawKey}filename',
          ],
        )
        .expand((x) => x)
        .toSet();

    final subjectEntries = credentialSubject.entries.where(
      (e) =>
          e.key != 'id' &&
          !attachmentKeys.contains(e.key) &&
          !attachmentFileNameKeys.contains(e.key),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status badges
        Row(
          children: [
            if (_onChainValid != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _onChainValid! ? AppColors.success : AppColors.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _onChainValid! ? l10n.valid : l10n.revoked,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_signatureValid != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _signatureValid! ? AppColors.success : AppColors.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _signatureValid! ? 'Valid Sig' : 'Invalid Sig',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        // Credential details - elevated card style
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(label: 'Type', value: type),
              if (id != null) _DetailRow(label: 'ID', value: id),
              _DetailRow(label: l10n.issuer, value: issuer),
              if (issuanceDate != null)
                _DetailRow(label: 'Issued At', value: _formatTimestamp(issuanceDate)),
              if (expirationDate != null)
                _DetailRow(label: 'Expiration', value: _formatTimestamp(expirationDate)),
              const SizedBox(height: 16),
              Text(
                'Credential Subject',
                style: TextStyle(
                  color: Colors.grey[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...subjectEntries.map(
                (entry) => _DetailRow(
                  label: entry.key,
                  value: entry.value.toString(),
                ),
              ),
              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Files',
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...attachments.map(
                  (attachment) => AttachmentRow(
                    attachment: attachment,
                    onView: () => _handleViewAttachment(attachment),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_previewingAttachment != null) ...[
          const SizedBox(height: 24),
          _buildAttachmentPreviewCard(),
        ],
      ],
    );
  }

  // --- Attachment helpers (reused from verification preview) ---

  List<CredentialAttachment> _extractFileAttachments(
    Map<String, dynamic>? doc,
  ) {
    if (doc == null) return const [];
    final subject = doc['credentialSubject'];
    if (subject is! Map<String, dynamic>) return const [];

    final attachments = <CredentialAttachment>[];
    subject.forEach((key, value) {
      if (value is! String || value.isEmpty) return;
      final lowerKey = key.toString().toLowerCase();
      if (!lowerKey.contains('file') && !lowerKey.contains('document')) return;
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

  String _formatFieldLabel(String key) {
    if (key.isEmpty) return 'Document';
    final buffer = StringBuffer();
    for (var i = 0; i < key.length; i++) {
      final char = key[i];
      if (i == 0) {
        buffer.write(char.toUpperCase());
        continue;
      }
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (isUpper) buffer.write(' ');
      buffer.write(char);
    }
    return buffer.toString().replaceAll('_', ' ');
  }

  List<GatewayLink> _buildGatewayLinks(String uri) {
    final links = <GatewayLink>[];

    final hash = _extractIpfsHash(uri);
    if (hash != null && hash.isNotEmpty) {
      // Prefer fast public gateways first
      final ipfsIo = 'https://ipfs.io/ipfs/$hash';
      if (!links.any((link) => link.url == ipfsIo)) {
        links.add(GatewayLink(label: 'ipfs.io', url: ipfsIo));
      }

      final dwebLink = 'https://dweb.link/ipfs/$hash';
      if (!links.any((link) => link.url == dwebLink)) {
        links.add(GatewayLink(label: 'dweb.link', url: dwebLink));
      }

      final cloudflare = 'https://cloudflare-ipfs.com/ipfs/$hash';
      if (!links.any((link) => link.url == cloudflare)) {
        links.add(GatewayLink(label: 'Cloudflare', url: cloudflare));
      }
    }

    // Pinata gateway as explicit option, but not default
    final defaultUrl = _pinataService.resolveToHttp(uri);
    if (defaultUrl.isNotEmpty &&
        !links.any((link) => link.url == defaultUrl)) {
      links.add(GatewayLink(label: 'Pinata', url: defaultUrl));
    }

    return links;
  }

  String? _extractIpfsHash(String uri) {
    if (uri.isEmpty) return null;
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

  bool _isImageFile(CredentialAttachment attachment) {
    final uri = attachment.uri.toLowerCase();
    final fileName = attachment.fileName?.toLowerCase() ?? '';
    return uri.contains('.jpg') ||
        uri.contains('.jpeg') ||
        uri.contains('.png') ||
        uri.contains('.gif') ||
        uri.contains('.webp') ||
        fileName.contains('.jpg') ||
        fileName.contains('.jpeg') ||
        fileName.contains('.png') ||
        fileName.contains('.gif') ||
        fileName.contains('.webp');
  }

  bool _isPdfFile(CredentialAttachment attachment) {
    final uri = attachment.uri.toLowerCase();
    final fileName = attachment.fileName?.toLowerCase() ?? '';
    return uri.contains('.pdf') || fileName.contains('.pdf');
  }

  Future<void> _openExternalLink(String url) async {
    // Use default browser through AttachmentPreviewFallback button
    // (kept simple here; VerificationRequestDetailDialog has full error handling)
    // ignore: deprecated_member_use
    await launchUrl(Uri.parse(url));
  }

  void _openFullscreenImage(String imageUrl, String? title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FullscreenImageViewer(
          imageUrl: imageUrl,
          title: title,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _openFullscreenPdf(String pdfUrl, String? title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FullscreenPdfViewer(
          pdfUrl: pdfUrl,
          title: title,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _handleViewAttachment(CredentialAttachment attachment) {
    setState(() {
      _previewingAttachment = attachment;
      final gateways = _buildGatewayLinks(attachment.uri);
      if (gateways.isNotEmpty) {
        _selectedGatewayLink = gateways.first;
      } else {
        final defaultUrl = _pinataService.resolveToHttp(attachment.uri);
        if (defaultUrl.isNotEmpty) {
          _selectedGatewayLink = GatewayLink(label: 'Default', url: defaultUrl);
        } else {
          _selectedGatewayLink =
              GatewayLink(label: 'Original', url: attachment.uri);
        }
      }
    });
  }

  Widget _buildAttachmentPreviewCard() {
    if (_previewingAttachment == null || _selectedGatewayLink == null) {
      return const SizedBox.shrink();
    }

    final attachment = _previewingAttachment!;
    final selectedLink = _selectedGatewayLink!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attachment.fileName ?? attachment.label,
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<GatewayLink>(
                initialValue: selectedLink,
                icon: const Icon(Icons.link),
                onSelected: (link) {
                  setState(() => _selectedGatewayLink = link);
                },
                itemBuilder: (context) {
                  final gateways = _buildGatewayLinks(attachment.uri);
                  if (gateways.isEmpty) {
                    final defaultUrl =
                        _pinataService.resolveToHttp(attachment.uri);
                    if (defaultUrl.isNotEmpty) {
                      return [
                        PopupMenuItem<GatewayLink>(
                          value: GatewayLink(label: 'Default', url: defaultUrl),
                          child: const Text('Default'),
                        ),
                      ];
                    }
                    return [
                      PopupMenuItem<GatewayLink>(
                        value: GatewayLink(
                          label: 'Original',
                          url: attachment.uri,
                        ),
                        child: const Text('Original'),
                      ),
                    ];
                  }
                  return gateways
                      .map(
                        (link) => PopupMenuItem<GatewayLink>(
                          value: link,
                          child: Text(link.label),
                        ),
                      )
                      .toList();
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _previewingAttachment = null;
                    _selectedGatewayLink = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: Center(
              child: _isImageFile(attachment)
                  ? GestureDetector(
                      onTap: () => _openFullscreenImage(
                        selectedLink.url,
                        attachment.fileName ?? attachment.label,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          selectedLink.url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return AttachmentPreviewFallback(
                              url: selectedLink.url,
                              onOpenExternal: () =>
                                  _openExternalLink(selectedLink.url),
                            );
                          },
                        ),
                      ),
                    )
                  : _isPdfFile(attachment)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              size: 48,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _openFullscreenPdf(
                                selectedLink.url,
                                attachment.fileName ?? attachment.label,
                              ),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Mở PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                              ),
                            ),
                          ],
                        )
                      : AttachmentPreviewFallback(
                          url: selectedLink.url,
                          onOpenExternal: () =>
                              _openExternalLink(selectedLink.url),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDIDDisplay(AppLocalizations l10n) {
    final didDoc = _fullData;
    if (didDoc == null) {
      return const SizedBox.shrink();
    }

    final id = didDoc['id'] as String? ?? '';
    final controller = didDoc['controller'] as String?;
    final alsoKnownAs = didDoc['alsoKnownAs'] as List?;
    final service = didDoc['service'] as List?;
    final verificationMethod = didDoc['verificationMethod'] as List?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailRow(label: 'DID', value: id),
          if (controller != null) _DetailRow(label: 'Controller', value: controller),
          if (alsoKnownAs != null && alsoKnownAs.isNotEmpty)
            _DetailRow(label: 'Also Known As', value: alsoKnownAs.join(', ')),
          if (service != null && service.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Services',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
              ...service.map((s) {
                final serviceMap = s as Map<String, dynamic>;
                return _DetailRow(
                  label: serviceMap['type']?.toString() ?? 'Service',
                  value: serviceMap['serviceEndpoint']?.toString() ?? '',
                );
              }),
          ],
          if (verificationMethod != null && verificationMethod.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Verification Methods',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...verificationMethod.map((vm) {
              final vmMap = vm as Map<String, dynamic>;
              return _DetailRow(
                label: vmMap['type']?.toString() ?? 'Method',
                value: vmMap['id']?.toString() ?? '',
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationDisplay(AppLocalizations l10n) {
    final data = _fullData;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final document = data['document'] as Map<String, dynamic>?;
    final valid = data['valid'] as bool?;
    final issuer = data['issuer'] as String?;
    final hash = data['hashCredential'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Verification result
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                _onChainValid == true ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: _onChainValid == true ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                _onChainValid == true ? l10n.valid : l10n.invalid,
                style: TextStyle(
                  color: _onChainValid == true ? AppColors.success : AppColors.danger,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_onChainValid == true)
                Text(
                  l10n.credentialVerified,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // VC details
        if (document != null) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (issuer != null) _DetailRow(label: l10n.issuer, value: issuer),
                if (hash != null) _DetailRow(label: 'Hash', value: hash),
                if (valid != null)
                  _DetailRow(label: 'Status', value: valid ? l10n.valid : l10n.revoked),
                const SizedBox(height: 16),
                Text(
                  'Credential Details',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...(document['credentialSubject'] as Map<String, dynamic>? ?? {}).entries.map(
                  (entry) => _DetailRow(
                    label: entry.key,
                    value: entry.value.toString(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

