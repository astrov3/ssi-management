import 'dart:io';

/// Service for OCR (Optical Character Recognition)
/// Note: OCR functionality will be implemented when ML Kit is properly configured
class OCRService {
  /// Recognize text from image file
  /// TODO: Implement with Google ML Kit or alternative OCR service
  Future<String> recognizeTextFromFile(File imageFile) async {
    // Placeholder - will be implemented with OCR library
    throw UnimplementedError('OCR functionality is not yet implemented. Please install and configure Google ML Kit.');
  }

  /// Check if OCR is available
  bool get isAvailable => false;

  /// Dispose resources
  void dispose() {
    // No-op for now, will be implemented when OCR is available
  }
}

