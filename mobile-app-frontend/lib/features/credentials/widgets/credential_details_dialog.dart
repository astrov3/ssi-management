import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ssi_app/features/credentials/models/credential_models.dart';
import 'package:ssi_app/features/credentials/widgets/credential_detail_widgets.dart';
import 'package:ssi_app/features/credentials/widgets/fullscreen_image_viewer.dart';
import 'package:ssi_app/features/credentials/widgets/fullscreen_pdf_viewer.dart';
import 'package:ssi_app/features/qr/display/qr_display_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CredentialDetailsDialog extends StatefulWidget {
  const CredentialDetailsDialog({
    super.key,
    required this.credential,
    required this.vcDocument,
    required this.signatureValid,
    required this.icon,
    required this.color,
    required this.title,
    required this.orgID,
    required this.onCopyHash,
    required this.attachments,
    required this.pinataService,
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
  final List<CredentialAttachment> attachments;
  final PinataService pinataService;
  final VoidCallback? onRevoke;
  final VoidCallback? onRequestVerification;
  final VoidCallback? onVerifyCredential;
  final void Function(
    CredentialAttachment attachment,
    BuildContext dialogContext,
  )?
  onViewAttachment;

  @override
  State<CredentialDetailsDialog> createState() =>
      _CredentialDetailsDialogState();
}

class _CredentialDetailsDialogState extends State<CredentialDetailsDialog> {
  CredentialAttachment? _previewingAttachment;
  GatewayLink? _selectedGatewayLink;

  int? _parseEpochSeconds(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is BigInt) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
      final date = DateTime.tryParse(value);
      if (date != null) {
        return (date.millisecondsSinceEpoch / 1000).round();
      }
    }
    return null;
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
    final defaultUrl = widget.pinataService.resolveToHttp(uri);
    if (defaultUrl.isNotEmpty &&
        !links.any((link) => link.url == defaultUrl)) {
      links.add(GatewayLink(label: 'Pinata', url: defaultUrl));
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

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.webp');
  }

  bool _isImageFile(CredentialAttachment? attachment) {
    if (attachment == null) return false;
    
    // Check fileName first (most reliable)
    if (attachment.fileName != null) {
      final lower = attachment.fileName!.toLowerCase();
      if (lower.endsWith('.png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.gif') ||
          lower.endsWith('.bmp') ||
          lower.endsWith('.webp')) {
        return true;
      }
    }
    
    // Fallback: check URL if fileName is not available
    if (_selectedGatewayLink != null) {
      return _isImageUrl(_selectedGatewayLink!.url);
    }
    
    return false;
  }

  bool _isPdfFile(CredentialAttachment? attachment) {
    if (attachment == null) return false;
    
    // Check fileName first (most reliable)
    if (attachment.fileName != null) {
      final lower = attachment.fileName!.toLowerCase();
      if (lower.endsWith('.pdf')) {
        return true;
      }
    }
    
    // Fallback: check URL if fileName is not available
    if (_selectedGatewayLink != null) {
      final lower = _selectedGatewayLink!.url.toLowerCase();
      return lower.endsWith('.pdf') || lower.contains('application/pdf');
    }
    
    return false;
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
    debugPrint(
      '[AttachmentPreview] Viewing attachment: ${attachment.label}, '
      'fileName: ${attachment.fileName ?? 'null'}, '
      'uri: ${attachment.uri}',
    );
    setState(() {
      _previewingAttachment = attachment;
      final gateways = _buildGatewayLinks(attachment.uri);
      if (gateways.isNotEmpty) {
        _selectedGatewayLink = gateways.first;
      } else {
        // Fallback to default URL if no gateways found
        final defaultUrl = widget.pinataService.resolveToHttp(attachment.uri);
        if (defaultUrl.isNotEmpty) {
          _selectedGatewayLink = GatewayLink(label: 'Default', url: defaultUrl);
        } else {
          _selectedGatewayLink = GatewayLink(label: 'Original', url: attachment.uri);
        }
      }
    });
    debugPrint(
      '[AttachmentPreview] Is image: ${_isImageFile(attachment)}, '
      'Is PDF: ${_isPdfFile(attachment)}, '
      'Selected gateway: ${_selectedGatewayLink?.url}',
    );
    if (widget.onViewAttachment != null) {
      widget.onViewAttachment!(attachment, context);
    }
  }

  void _showCredentialQrDialog() {
    final qrPayload = {
      'type': 'VC',
      'orgID': widget.orgID,
      'index': widget.credential['index'],
      'hashCredential': widget.credential['hashCredential'],
      'uri': widget.credential['uri'],
      'issuer': widget.credential['issuer'],
    };
    final qrString = jsonEncode(qrPayload);
    final credentialTitle = widget.title;
    final isVerified = widget.credential['verified'] == true;
    final isValid = widget.credential['valid'] != false;

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

  @override
  Widget build(BuildContext context) {
    bool isAttachmentKey(String key) {
      for (final attachment in widget.attachments) {
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

    final issuedAtSeconds = _parseEpochSeconds(widget.credential['issuedAt']);
    final expirationSeconds = _parseEpochSeconds(widget.credential['expirationDate']);
    final verifiedSeconds = _parseEpochSeconds(widget.credential['verifiedAt']);

    return Dialog(
      backgroundColor: Colors.white,
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
                      color: widget.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
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
                                color: (widget.credential['valid']
                                        ? AppColors.success
                                        : AppColors.danger)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.credential['valid']
                                    ? AppLocalizations.of(context)!.valid
                                    : AppLocalizations.of(context)!.revoked,
                                style: TextStyle(
                                  color:
                                      widget.credential['valid']
                                          ? AppColors.success
                                          : AppColors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (widget.credential['verified'] == true) ...[
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
              CredentialDetailRow(
                label: AppLocalizations.of(context)!.index,
                value: widget.credential['index'].toString(),
              ),
              CredentialDetailRow(
                label: AppLocalizations.of(context)!.issuer,
                value: widget.credential['issuer'],
              ),
              CredentialDetailRow(
                label: AppLocalizations.of(context)!.credentialHash,
                value: widget.credential['hashCredential'],
              ),
              CredentialDetailRow(label: 'URI', value: widget.credential['uri']),
              if (issuedAtSeconds != null)
                CredentialDetailRow(
                  label: 'Issued At',
                  value: DateTime.fromMillisecondsSinceEpoch(
                    issuedAtSeconds * 1000,
                  ).toIso8601String(),
                ),
              if (expirationSeconds != null && expirationSeconds > 0)
                CredentialDetailRow(
                  label: 'Expiration',
                  value: DateTime.fromMillisecondsSinceEpoch(
                    expirationSeconds * 1000,
                  ).toIso8601String(),
                ),
              if (widget.credential['verified'] == true) ...[
                if (widget.credential['verifier'] != null)
                  CredentialDetailRow(
                    label: 'Verified By',
                    value: widget.credential['verifier'],
                  ),
                if (verifiedSeconds != null && verifiedSeconds > 0)
                  CredentialDetailRow(
                    label: 'Verified At',
                    value: DateTime.fromMillisecondsSinceEpoch(
                      verifiedSeconds * 1000,
                    ).toIso8601String(),
                  ),
              ],
              if (widget.vcDocument != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CredentialDetailRow(
                  label: 'Type',
                  value:
                      (widget.vcDocument!['type'] as List?)?.join(', ') ??
                      'VerifiableCredential',
                ),
                CredentialDetailRow(
                  label: 'Subject',
                  value:
                      (widget.vcDocument!['credentialSubject'] as Map?)?['id']
                          ?.toString() ??
                      '',
                ),
                if ((widget.vcDocument!['credentialSubject'] as Map?) != null)
                  ...((widget.vcDocument!['credentialSubject'] as Map).entries
                      .where(
                        (e) =>
                            e.key != 'id' && !isAttachmentKey(e.key.toString()),
                      )
                      .map(
                        (e) => CredentialDetailRow(
                          label: e.key.toString(),
                          value: e.value.toString(),
                        ),
                      )),
                if (widget.signatureValid != null)
                  CredentialDetailRow(
                    label: 'Signature',
                    value: widget.signatureValid! ? 'Valid' : 'Invalid',
                  ),
              ],
              if (widget.attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Files',
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children:
                      widget.attachments.map((attachment) {
                        return AttachmentRow(
                          attachment: attachment,
                          onView: () => _handleViewAttachment(attachment),
                        );
                      }).toList(),
                ),
              ],
              if (_previewingAttachment != null) ...[
                const SizedBox(height: 24),
                Container(
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
                          Icon(
                            Icons.insert_drive_file,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _previewingAttachment!.fileName ?? _previewingAttachment!.label,
                              style: TextStyle(
                                color: Colors.grey[900],
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedGatewayLink != null)
                            PopupMenuButton<GatewayLink>(
                              initialValue: _selectedGatewayLink,
                              icon: Icon(Icons.link, color: Colors.grey[700], size: 20),
                              onSelected: (link) {
                                setState(() {
                                  _selectedGatewayLink = link;
                                });
                              },
                              itemBuilder: (context) {
                                final gateways = _buildGatewayLinks(_previewingAttachment!.uri);
                                // Include fallback if gateways is empty
                                if (gateways.isEmpty) {
                                  final defaultUrl = widget.pinataService.resolveToHttp(_previewingAttachment!.uri);
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
                              color: Colors.grey[700],
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
                            child: _isImageFile(_previewingAttachment)
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
                              : _isPdfFile(_previewingAttachment)
                                  ? GestureDetector(
                                      onTap: () => _openFullscreenPdf(
                                        _selectedGatewayLink!.url,
                                        _previewingAttachment?.fileName ??
                                            _previewingAttachment?.label,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: WebViewWidget(
                                                  controller: WebViewController()
                                                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                                                    ..setNavigationDelegate(
                                                      NavigationDelegate(
                                                        onPageFinished: (url) {
                                                          debugPrint('PDF loaded: $url');
                                                        },
                                                        onWebResourceError: (error) {
                                                          debugPrint('PDF load error: ${error.description}');
                                                        },
                                                      ),
                                                    )
                                                    ..loadRequest(
                                                      Uri.parse(
                                                        'https://docs.google.com/viewer?url=${Uri.encodeComponent(_selectedGatewayLink!.url)}&embedded=true',
                                                      ),
                                                    ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _previewingAttachment?.fileName ?? 'Document',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 12,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.open_in_new,
                                                    color: Colors.grey[700],
                                                    size: 20,
                                                  ),
                                                  onPressed: () => _openExternalLink(_selectedGatewayLink!.url),
                                                  tooltip: 'Mở PDF trong trình duyệt',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : AttachmentPreviewFallback(
                                      url: _selectedGatewayLink!.url,
                                      onOpenExternal: () => _openExternalLink(_selectedGatewayLink!.url),
                                    ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Gateway',
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: () {
                          final gateways = _buildGatewayLinks(_previewingAttachment!.uri);
                          if (gateways.isEmpty && _selectedGatewayLink != null) {
                            return [
                              ChoiceChip(
                                label: Text(
                                  _selectedGatewayLink!.label,
                                  style: TextStyle(color: Colors.grey[900]),
                                ),
                                selected: true,
                                onSelected: null,
                                selectedColor: AppColors.secondary.withValues(alpha: 0.3),
                                backgroundColor: Colors.grey[100],
                              ),
                            ];
                          }
                          return gateways
                              .map(
                                (link) => ChoiceChip(
                                  label: Text(
                                    link.label,
                                    style: TextStyle(color: Colors.grey[900]),
                                  ),
                                  selected: _selectedGatewayLink?.url == link.url,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedGatewayLink = link;
                                    });
                                  },
                                  selectedColor: AppColors.secondary.withValues(alpha: 0.3),
                                  backgroundColor: Colors.grey[100],
                                ),
                              )
                              .toList();
                        }(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onCopyHash,
                      icon: const Icon(Icons.copy),
                      label: Text(AppLocalizations.of(context)!.copyHash),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showCredentialQrDialog,
                      icon: const Icon(Icons.qr_code_2),
                      label: Text(AppLocalizations.of(context)!.myQrCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (widget.onRequestVerification != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onRequestVerification,
                        icon: const Icon(Icons.send),
                        label: const Text('Request Verification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  if (widget.onVerifyCredential != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onVerifyCredential,
                        icon: const Icon(Icons.verified),
                        label: const Text('Verify'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  if (widget.onRevoke != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onRevoke,
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

