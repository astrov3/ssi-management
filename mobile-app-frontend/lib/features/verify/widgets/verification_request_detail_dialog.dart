import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/features/credentials/models/credential_models.dart';
import 'package:ssi_app/features/credentials/widgets/credential_detail_widgets.dart';
import 'package:ssi_app/features/credentials/widgets/fullscreen_image_viewer.dart';
import 'package:ssi_app/features/credentials/widgets/fullscreen_pdf_viewer.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:url_launcher/url_launcher.dart';

class VerificationRequestDetailDialog extends StatefulWidget {
  const VerificationRequestDetailDialog({
    super.key,
    required this.request,
    this.credentialData,
    required this.isTrustedVerifier,
    this.currentAddress,
    required this.onVerify,
    this.onCancel,
    this.onRefresh,
  });

  final Map<String, dynamic> request;
  final Map<String, dynamic>? credentialData;
  final bool isTrustedVerifier;
  final String? currentAddress;
  final VoidCallback onVerify;
  final VoidCallback? onCancel;
  final VoidCallback? onRefresh;

  @override
  State<VerificationRequestDetailDialog> createState() => _VerificationRequestDetailDialogState();
}

class _VerificationRequestDetailDialogState extends State<VerificationRequestDetailDialog> {
  final _pinataService = PinataService();
  CredentialAttachment? _previewingAttachment;
  GatewayLink? _selectedGatewayLink;

  List<CredentialAttachment> _extractFileAttachments(Map<String, dynamic>? doc) {
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

  String _formatFieldLabel(String key) {
    final buffer = StringBuffer();
    for (var i = 0; i < key.length; i++) {
      final char = key[i];
      if (i == 0) {
        buffer.write(char.toUpperCase());
      } else if (char == char.toUpperCase() && char != char.toLowerCase()) {
        buffer.write(' ');
        buffer.write(char);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString().replaceAll('_', ' ');
  }

  List<GatewayLink> _buildGatewayLinks(String uri) {
    final links = <GatewayLink>[];
    final defaultUrl = _pinataService.resolveToHttp(uri);
    if (defaultUrl.isNotEmpty) {
      links.add(GatewayLink(label: 'Pinata', url: defaultUrl));
    }

    final hash = _extractIpfsHash(uri);
    if (hash != null && hash.isNotEmpty) {
      final ipfsIo = 'https://ipfs.io/ipfs/$hash';
      if (!links.any((link) => link.url == ipfsIo)) {
        links.add(GatewayLink(label: 'ipfs.io', url: ipfsIo));
      }

      final dwebLink = 'https://dweb.link/ipfs/$hash';
      if (!links.any((link) => link.url == dwebLink)) {
        links.add(GatewayLink(label: 'dweb.link', url: dwebLink));
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
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw 'Cannot open link';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open file: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
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
          _selectedGatewayLink = GatewayLink(label: 'Original', url: attachment.uri);
        }
      }
    });
  }

  String _formatAddress(String address) {
    if (address.isEmpty) return '';
    if (address.length < 14) return address; // Need at least 14 chars for 8+...6 format
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _canVerify() {
    if (!widget.isTrustedVerifier) return false;
    
    final targetVerifier = widget.request['targetVerifier'] as String?;
    if (targetVerifier == null || targetVerifier.isEmpty) return true;
    
    if (targetVerifier.toLowerCase() == '0x0000000000000000000000000000000000000000') {
      return true;
    }
    
    return widget.currentAddress?.toLowerCase() == targetVerifier.toLowerCase();
  }

  bool _canCancel() {
    final requester = widget.request['requester'] as String?;
    return widget.currentAddress?.toLowerCase() == requester?.toLowerCase();
  }

  Widget _buildCredentialData() {
    if (widget.credentialData == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Unable to load credential information',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final subject = widget.credentialData!['credentialSubject'] as Map<String, dynamic>?;
    if (subject == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Credential has no data',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Extract attachments
    final attachments = _extractFileAttachments(widget.credentialData);
    
    // Filter out attachment keys from subject entries
    final attachmentKeys = attachments.map((a) => a.rawKey).toSet();
    final attachmentFileNameKeys = attachments
        .map((a) => [
              '${a.rawKey}FileName',
              '${a.rawKey}Filename',
              '${a.rawKey}fileName',
              '${a.rawKey}filename',
            ])
        .expand((x) => x)
        .toSet();
    
    final entries = subject.entries
        .where((e) => 
            e.key != 'id' && 
            !attachmentKeys.contains(e.key) &&
            !attachmentFileNameKeys.contains(e.key))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Regular fields
        if (entries.isNotEmpty)
          ...entries.map((entry) {
            final key = entry.key;
            final value = entry.value?.toString() ?? 'N/A';
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatFieldLabel(key),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        
        // Attachments section
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Files',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...attachments.map((attachment) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AttachmentRow(
                attachment: attachment,
                onView: () => _handleViewAttachment(attachment),
              ),
            );
          }),
        ],
        
        // Preview section
        if (_previewingAttachment != null) ...[
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _previewingAttachment!.fileName ?? _previewingAttachment!.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedGatewayLink != null)
                      PopupMenuButton<GatewayLink>(
                        initialValue: _selectedGatewayLink,
                        icon: Icon(Icons.link, color: Colors.white.withValues(alpha: 0.7), size: 20),
                        onSelected: (link) {
                          setState(() {
                            _selectedGatewayLink = link;
                          });
                        },
                        itemBuilder: (context) {
                          final gateways = _buildGatewayLinks(_previewingAttachment!.uri);
                          if (gateways.isEmpty) {
                            final defaultUrl = _pinataService.resolveToHttp(_previewingAttachment!.uri);
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
                                value: GatewayLink(label: 'Original', url: _previewingAttachment!.uri),
                                child: const Text('Original'),
                              ),
                            ];
                          }
                          return gateways.map(
                            (link) => PopupMenuItem<GatewayLink>(
                              value: link,
                              child: Text(link.label),
                            ),
                          ).toList();
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
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
                if (_selectedGatewayLink != null)
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: _isImageFile(_previewingAttachment!)
                          ? GestureDetector(
                              onTap: () => _openFullscreenImage(
                                _selectedGatewayLink!.url,
                                _previewingAttachment?.fileName ??
                                    _previewingAttachment?.label,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 3.0,
                                  child: Image.network(
                                    _selectedGatewayLink!.url,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: progress.expectedTotalBytes != null
                                              ? progress.cumulativeBytesLoaded /
                                                  (progress.expectedTotalBytes ?? 1)
                                              : null,
                                          color: AppColors.secondary,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return AttachmentPreviewFallback(
                                        url: _selectedGatewayLink!.url,
                                        onOpenExternal: () => _openExternalLink(_selectedGatewayLink!.url),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            )
                          : _isPdfFile(_previewingAttachment!)
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      size: 48,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'PDF Preview',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => _openFullscreenPdf(
                                        _selectedGatewayLink!.url,
                                        _previewingAttachment?.fileName ??
                                            _previewingAttachment?.label,
                                      ),
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Mở PDF'),
                                      // Button uses English label for consistency with other dialogs
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                )
                              : AttachmentPreviewFallback(
                                  url: _selectedGatewayLink!.url,
                                  onOpenExternal: () => _openExternalLink(_selectedGatewayLink!.url),
                                ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgID = widget.request['orgID'] as String? ?? 'N/A';
    final vcIndex = widget.request['vcIndex'] as int? ?? 0;
    final requester = widget.request['requester'] as String? ?? 'N/A';
    final targetVerifier = widget.request['targetVerifier'] as String?;
    final metadataUri = widget.request['metadataUri'] as String? ?? '';
    final requestedAt = widget.request['requestedAt'] as int? ?? 0;
    
    final canVerify = _canVerify();
    final canCancel = _canCancel();
    final isAnyVerifier = targetVerifier == null || 
        targetVerifier.isEmpty || 
        targetVerifier.toLowerCase() == '0x0000000000000000000000000000000000000000';
    
    // Get verifier display value
    // Compute verifier display text (any or specific address)
    final String verifierDisplay = isAnyVerifier
        ? 'Any verifier'
        : _formatAddress(targetVerifier);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Verification Request Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Request Info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request Information',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'VC Index',
                            value: '#$vcIndex',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'OrgID',
                            value: _formatAddress(orgID),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Requester',
                            value: _formatAddress(requester),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: isAnyVerifier ? 'Verifier' : 'Target Verifier',
                            value: verifierDisplay,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Requested At',
                            value: _formatTimestamp(requestedAt),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Metadata URI',
                            value: metadataUri.isNotEmpty 
                                ? (metadataUri.length > 30 ? '${metadataUri.substring(0, 30)}...' : metadataUri)
                                : 'N/A',
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(color: Colors.white24),
                    
                    // Credential Data
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Credential Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCredentialData(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canCancel)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCancel?.call();
                      },
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  if (canCancel && canVerify) const SizedBox(width: 8),
                  if (canVerify)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onVerify();
                      },
                      icon: const Icon(Icons.verified, size: 18),
                      label: const Text('Verify Credential'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

