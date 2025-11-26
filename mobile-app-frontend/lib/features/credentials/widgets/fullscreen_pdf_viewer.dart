import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FullscreenPdfViewer extends StatelessWidget {
  const FullscreenPdfViewer({
    super.key,
    required this.pdfUrl,
    this.title,
  });

  final String pdfUrl;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: title != null
            ? Text(
                title!,
                style: const TextStyle(color: Colors.white),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Đóng',
          ),
        ],
      ),
      body: WebViewWidget(
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
              'https://docs.google.com/viewer?url=${Uri.encodeComponent(pdfUrl)}&embedded=true',
            ),
          ),
      ),
    );
  }
}

