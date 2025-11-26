import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ssi_app/features/credentials/widgets/credential_detail_widgets.dart';
import 'package:ssi_app/features/credentials/widgets/fullscreen_image_viewer.dart';
import 'package:ssi_app/features/credentials/widgets/fullscreen_pdf_viewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DIDDetailsDialog extends StatefulWidget {
  const DIDDetailsDialog({
    super.key,
    required this.didData,
    required this.didDocument,
    required this.pinataService,
  });

  final Map<String, dynamic> didData;
  final Map<String, dynamic>? didDocument;
  final PinataService pinataService;

  @override
  State<DIDDetailsDialog> createState() => _DIDDetailsDialogState();
}

class _DIDDetailsDialogState extends State<DIDDetailsDialog> {
  String? _previewingFileUri;
  String? _previewingFileName;
  GatewayLink? _selectedGatewayLink;

  List<GatewayLink> _buildGatewayLinks(String uri) {
    final links = <GatewayLink>[];
    final defaultUrl = widget.pinataService.resolveToHttp(uri);
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

  String? _extractFileNameFromUri(String uri) {
    if (uri.isEmpty) return null;
    // Try to extract from query parameters first
    final uriObj = Uri.tryParse(uri);
    if (uriObj != null) {
      final filename = uriObj.queryParameters['filename'] ?? 
                      uriObj.queryParameters['name'];
      if (filename != null && filename.isNotEmpty) {
        return filename;
      }
    }
    // Try to extract from path
    final segments = uri.split('/');
    if (segments.isNotEmpty) {
      final lastSegment = segments.last.split('?').first;
      if (lastSegment.isNotEmpty && lastSegment.contains('.')) {
        return lastSegment;
      }
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

  bool _isPdfUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.pdf') || lower.contains('application/pdf');
  }

  bool _isImageFile(String? fileName, String? url) {
    // Check fileName first (most reliable)
    if (fileName != null) {
      final lower = fileName.toLowerCase();
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
    if (url != null) {
      return _isImageUrl(url);
    }
    
    return false;
  }

  bool _isPdfFile(String? fileName, String? url) {
    // Check fileName first (most reliable)
    if (fileName != null) {
      final lower = fileName.toLowerCase();
      if (lower.endsWith('.pdf')) {
        return true;
      }
    }
    
    // Fallback: check URL if fileName is not available
    if (url != null) {
      return _isPdfUrl(url);
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

  void _handleViewFile(String uri, String? fileName) {
    setState(() {
      _previewingFileUri = uri;
      _previewingFileName = fileName;
      final gateways = _buildGatewayLinks(uri);
      if (gateways.isNotEmpty) {
        _selectedGatewayLink = gateways.first;
      } else {
        final defaultUrl = widget.pinataService.resolveToHttp(uri);
        if (defaultUrl.isNotEmpty) {
          _selectedGatewayLink = GatewayLink(label: 'Default', url: defaultUrl);
        } else {
          _selectedGatewayLink = GatewayLink(label: 'Original', url: uri);
        }
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label đã được sao chép'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 14,
                    ),
                  ),
                ),
                if (canCopy)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    color: Colors.grey[600],
                    onPressed: () => _copyToClipboard(value, label),
                    tooltip: 'Sao chép',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.didDocument?['metadata'] as Map<String, dynamic>?;
    final logoUri = metadata?['logo'] as String?;
    final documentUri = metadata?['document'] as String?;
    final serviceEndpoint = (widget.didDocument?['service'] as List?)?.isNotEmpty == true
        ? (widget.didDocument?['service'] as List).first['serviceEndpoint'] as String?
        : null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.badge, color: AppColors.secondary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metadata?['name']?.toString() ?? 'DID Information',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (widget.didData['active'] as bool
                                    ? AppColors.success
                                    : AppColors.danger)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.didData['active'] as bool ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: widget.didData['active'] as bool
                                  ? AppColors.success
                                  : AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Blockchain Information',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Organization ID', widget.didData['orgID'] ?? '', canCopy: true),
              _buildDetailRow('Owner', widget.didData['owner'] ?? '', canCopy: true),
              _buildDetailRow('Hash', widget.didData['hashData'] ?? '', canCopy: true),
              _buildDetailRow('URI', widget.didData['uri'] ?? '', canCopy: true),
              if (widget.didDocument != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'DID Document',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('ID', widget.didDocument!['id']?.toString() ?? ''),
                _buildDetailRow('Controller', widget.didDocument!['controller']?.toString() ?? ''),
                if (serviceEndpoint != null)
                  _buildDetailRow('Service Endpoint', serviceEndpoint),
                if (widget.didDocument!['updated'] != null)
                  _buildDetailRow('Updated', widget.didDocument!['updated']?.toString() ?? ''),
                if (widget.didDocument!['created'] != null)
                  _buildDetailRow('Created', widget.didDocument!['created']?.toString() ?? ''),
              ],
              if (metadata != null && metadata.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Metadata',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...metadata.entries
                    .where((e) => e.key != 'logo' && e.key != 'document')
                    .map((e) => _buildDetailRow(
                          e.key,
                          e.value?.toString() ?? '',
                        )),
              ],
              if (logoUri != null || documentUri != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Files',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (logoUri != null)
                  ListTile(
                    leading: const Icon(Icons.image, color: AppColors.secondary),
                    title: const Text('Logo'),
                    subtitle: Text(
                      _extractFileNameFromUri(logoUri) ?? 'logo',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _handleViewFile(logoUri, _extractFileNameFromUri(logoUri) ?? 'logo'),
                  ),
                if (documentUri != null)
                  ListTile(
                    leading: const Icon(Icons.insert_drive_file, color: AppColors.secondary),
                    title: const Text('Document'),
                    subtitle: Text(
                      _extractFileNameFromUri(documentUri) ?? 'document',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _handleViewFile(documentUri, _extractFileNameFromUri(documentUri) ?? 'document'),
                  ),
              ],
              if (_previewingFileUri != null && _selectedGatewayLink != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: Colors.grey[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _previewingFileName ?? 'File',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_buildGatewayLinks(_previewingFileUri!).isNotEmpty)
                            PopupMenuButton<GatewayLink>(
                              initialValue: _selectedGatewayLink,
                              icon: Icon(Icons.link, color: Colors.grey[700], size: 20),
                              onSelected: (link) {
                                setState(() {
                                  _selectedGatewayLink = link;
                                });
                              },
                              itemBuilder: (context) {
                                final gateways = _buildGatewayLinks(_previewingFileUri!);
                                return gateways
                                    .map((link) => PopupMenuItem<GatewayLink>(
                                          value: link,
                                          child: Text(link.label),
                                        ))
                                    .toList();
                              },
                            ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[700], size: 20),
                            onPressed: () {
                              setState(() {
                                _previewingFileUri = null;
                                _previewingFileName = null;
                                _selectedGatewayLink = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: Center(
                          child: _isImageFile(_previewingFileName, _selectedGatewayLink!.url)
                              ? GestureDetector(
                                  onTap: () => _openFullscreenImage(
                                    _selectedGatewayLink!.url,
                                    _previewingFileName,
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
                              : _isPdfFile(_previewingFileName, _selectedGatewayLink!.url)
                                  ? GestureDetector(
                                      onTap: () => _openFullscreenPdf(
                                        _selectedGatewayLink!.url,
                                        _previewingFileName,
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
                                                    _previewingFileName ?? 'Document',
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
                                                  icon: Icon(Icons.open_in_new, color: Colors.grey[700], size: 20),
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
                          final gateways = _buildGatewayLinks(_previewingFileUri!);
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(
                    widget.didData['hashData'] ?? '',
                    'Hash',
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Hash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GatewayLink {
  final String label;
  final String url;

  GatewayLink({required this.label, required this.url});
}

