import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final Barcode barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    // Stop the scanner
    _controller.stop();

    // Process the QR code data
    _processQRData(barcode.rawValue!);
  }

  void _processQRData(String data) {
    try {
      // Try to parse as JSON first
      final Map<String, dynamic>? parsed = jsonDecode(data) as Map<String, dynamic>?;
      
      if (parsed != null) {
        // Return parsed JSON data (even without 'type' field for credential forms)
        Navigator.of(context).pop(parsed);
        return;
      }
    } catch (_) {
      // Not JSON, try to parse as structured text format
      // Format: KEY1:VALUE1|KEY2:VALUE2|KEY3:VALUE3
      try {
        final parts = data.split('|');
        final parsedData = <String, dynamic>{};
        
        for (var part in parts) {
          final keyValue = part.split(':');
          if (keyValue.length == 2) {
            parsedData[keyValue[0].trim()] = keyValue[1].trim();
          }
        }
        
        if (parsedData.isNotEmpty) {
          Navigator.of(context).pop(parsedData);
          return;
        }
      } catch (_) {
        // Not structured text either
      }
    }

    // If we can't parse it, show options to the user
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'QR Code Data',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nội dung QR code:',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              data.length > 100 ? '${data.substring(0, 100)}...' : data,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Courier'),
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn có muốn sử dụng dữ liệu này?',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
              _controller.start();
            },
            child: Text(
              'Thử lại',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Return raw data as map
              Navigator.of(context).pop({'rawData': data});
            },
            child: Text(
              'Sử dụng',
              style: const TextStyle(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.scanQr,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay with scanning area
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: Container(),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.positionQRCodeInFrame,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Calculate scanning area (square in center)
    final scanningAreaSize = size.width * 0.7;
    final left = (size.width - scanningAreaSize) / 2;
    final top = (size.height - scanningAreaSize) / 2 - 50;
    final scanningArea = Rect.fromLTWH(left, top, scanningAreaSize, scanningAreaSize);

    // Draw dark overlay
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final scanningPath = Path()
      ..addRect(scanningArea);
    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanningPath,
    );
    canvas.drawPath(overlayPath, paint);

    // Draw corner brackets
    final cornerLength = 20.0;
    final cornerWidth = 4.0;
    final cornerPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + scanningAreaSize - cornerLength, top),
      Offset(left + scanningAreaSize, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanningAreaSize, top),
      Offset(left + scanningAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanningAreaSize - cornerLength),
      Offset(left, top + scanningAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanningAreaSize),
      Offset(left + cornerLength, top + scanningAreaSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanningAreaSize - cornerLength, top + scanningAreaSize),
      Offset(left + scanningAreaSize, top + scanningAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanningAreaSize, top + scanningAreaSize - cornerLength),
      Offset(left + scanningAreaSize, top + scanningAreaSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

