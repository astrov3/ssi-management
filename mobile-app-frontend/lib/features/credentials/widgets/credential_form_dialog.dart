import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/features/qr/scanner/qr_scanner_screen.dart';
import 'package:ssi_app/features/credentials/models/credential_template.dart';
import 'package:ssi_app/services/ocr/ocr_service.dart';
import 'package:ssi_app/services/parser/document_parser_service.dart';
import 'package:ssi_app/features/credentials/widgets/credential_form_field.dart';

/// Dialog for issuing credentials with template-based forms
class CredentialFormDialog extends StatefulWidget {
  final Future<bool> Function(Map<String, dynamic> credentialData) onSubmit;

  const CredentialFormDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<CredentialFormDialog> createState() => _CredentialFormDialogState();
}

class _CredentialFormDialogState extends State<CredentialFormDialog> {
  CredentialTemplate? _selectedTemplate;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _fieldValues = {};
  final Map<String, String> _fieldErrors = {};
  final _documentParserService = DocumentParserService();
  final _ocrService = OCRService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _ocrService.dispose();
    super.dispose();
  }

  /// Scan QR code and auto-fill form
  Future<void> _scanQRCode() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectCredentialTypeFirst),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
      );

      if (result != null && mounted) {
        // Try to parse QR code data
        Map<String, dynamic>? parsedData;
        
        // If result is already a Map, try to parse it
        if (result.isNotEmpty) {
          // Check if it's already in the right format (has credential fields)
          final hasCredentialFields = result.keys.any((key) => 
            ['fullName', 'idNumber', 'passportNumber', 'licenseNumber', 'dateOfBirth'].contains(key)
          );
          
          if (hasCredentialFields) {
            // Use directly if it already has credential fields
            parsedData = result;
          } else {
            // Try to parse as JSON string or structured text
            try {
              parsedData = _documentParserService.parseQRCodeData(result.toString());
            } catch (e) {
              // If parsing fails, try to map the result directly
              parsedData = result;
            }
          }
        }
        
        if (parsedData != null && parsedData.isNotEmpty) {
          // Map to credential fields based on template
          final mappedData = _documentParserService.mapToCredentialFields(
            parsedData,
            _selectedTemplate!.id,
          );
          
          // Merge with original data to keep any extra fields
          mappedData.addAll(parsedData);
          
          // Auto-fill form
          _fillFormFromData(mappedData);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.informationFilledFromQR),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.cannotReadQRCode),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorScanningQR(e.toString())),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Capture image and extract text using OCR
  Future<void> _captureAndOCR() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectCredentialTypeFirst),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      // Show dialog to choose camera or gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l10n.selectImageSource, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
                title: Text(l10n.takePhoto, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.secondary),
                title: Text(l10n.chooseFromGallery, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          ),
        );
      }

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null && mounted) {
        Navigator.pop(context); // Close loading

        // Check if OCR is available
        if (!_ocrService.isAvailable) {
          // For now, just save the image file path
          final file = File(image.path);
          _fieldValues['documentFile'] = file.path;
          _controllers['documentFile']?.text = image.name;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.imageSavedOCRLater),
                backgroundColor: AppColors.secondary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          setState(() {});
          return;
        }

        // TODO: Implement OCR when ML Kit is configured
        // Try OCR
        try {
          final ocrText = await _ocrService.recognizeTextFromFile(File(image.path));
          
          // Parse OCR text
          final parsedData = _documentParserService.parseStructuredText(
            ocrText,
            _selectedTemplate!.id,
          );
          
          if (parsedData != null) {
            // Map to credential fields
            final mappedData = _documentParserService.mapToCredentialFields(
              parsedData,
              _selectedTemplate!.id,
            );
            
            // Also save the image
            mappedData['documentFile'] = image.path;
            
            // Auto-fill form
            _fillFormFromData(mappedData);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.informationFilledFromImage),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            // Just save the image if parsing fails
            _fieldValues['documentFile'] = image.path;
            _controllers['documentFile']?.text = image.name;
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.cannotReadFromImage),
                  backgroundColor: AppColors.secondary,
                ),
              );
            }
            setState(() {});
          }
        } catch (e) {
          // OCR failed, just save the image
          _fieldValues['documentFile'] = image.path;
          _controllers['documentFile']?.text = image.name;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.errorOCR(e.toString())),
                backgroundColor: AppColors.secondary,
              ),
            );
          }
          setState(() {});
        }
      } else if (mounted) {
        Navigator.pop(context); // Close loading if image pick was cancelled
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading on error
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred(e.toString())),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Fill form fields from parsed data
  void _fillFormFromData(Map<String, dynamic> data) {
    setState(() {
      for (var entry in data.entries) {
        final key = entry.key;
        final value = entry.value?.toString() ?? '';
        
        if (_controllers.containsKey(key)) {
          _controllers[key]!.text = value;
          _fieldValues[key] = value;
        } else {
          _fieldValues[key] = value;
        }
      }
    });
  }

  void _selectTemplate(CredentialTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _fieldValues.clear();
      _fieldErrors.clear();
      
      // Initialize controllers for all fields
      for (var field in template.fields) {
        if (!_controllers.containsKey(field.key)) {
          _controllers[field.key] = TextEditingController();
        }
        _controllers[field.key]!.clear();
      }
    });
  }

  Future<void> _validateAndSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSubmitting) return;
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectCredentialType),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Validate required fields
    _fieldErrors.clear();
    bool isValid = true;

    for (var field in _selectedTemplate!.fields) {
      if (field.required) {
        final value = _fieldValues[field.key] ?? _controllers[field.key]?.text ?? '';
        if (value.isEmpty) {
          _fieldErrors[field.key] = l10n.fieldRequired(field.label);
          isValid = false;
        }
      }

      // Validate regex if provided
      if (field.validationRegex != null) {
        final value = _fieldValues[field.key] ?? _controllers[field.key]?.text ?? '';
        if (value.isNotEmpty) {
          final regex = RegExp(field.validationRegex!);
          if (!regex.hasMatch(value)) {
            _fieldErrors[field.key] = field.validationMessage ?? l10n.invalidValue;
            isValid = false;
          }
        }
      }
    }

    if (!isValid) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseFillRequiredFields),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Build payload
    final payload = <String, dynamic>{
      'type': _selectedTemplate!.vcType,
    };

    // Add all field values
    for (var field in _selectedTemplate!.fields) {
      final value = _fieldValues[field.key] ?? _controllers[field.key]?.text ?? '';
      if (value.isNotEmpty) {
        payload[field.key] = value;
      }
    }

    // Add expiration date if provided
    if (payload.containsKey('expiryDate')) {
      payload['expirationDate'] = payload['expiryDate'];
    } else if (payload.containsKey('validTo')) {
      payload['expirationDate'] = payload['validTo'];
    } else if (payload.containsKey('endDate')) {
      payload['expirationDate'] = payload['endDate'];
    }

    setState(() {
      _isSubmitting = true;
    });

    bool success = false;
    try {
      success = await widget.onSubmit(payload);
    } catch (e) {
      success = false;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    l10n.createNewCredential,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Template selection
            if (_selectedTemplate == null)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectCredentialType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...CredentialTemplates.templates.map((template) {
                        final title = CredentialTemplates.getTemplateName(template, l10n);
                        final description = CredentialTemplates.getTemplateDescription(template, l10n);
                        return _TemplateCard(
                          template: template,
                          title: title,
                          description: description,
                          onTap: () => _selectTemplate(template),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              )
            else
              // Form fields
              Expanded(
                child: Builder(
                  builder: (context) {
                    final templateTitle = CredentialTemplates.getTemplateName(_selectedTemplate!, l10n);
                    final templateDescription = CredentialTemplates.getTemplateDescription(_selectedTemplate!, l10n);

                    return Column(
                      children: [
                        // Template info and back button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border(
                              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _selectedTemplate = null;
                                    _fieldValues.clear();
                                    _fieldErrors.clear();
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Icon(_selectedTemplate!.icon, color: AppColors.secondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      templateTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      templateDescription,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Form fields
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                            // Quick actions: Scan QR and OCR
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _scanQRCode,
                                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                                      label: Text(l10n.scanQR, style: const TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.secondary,
                                        side: BorderSide(color: AppColors.secondary),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _captureAndOCR,
                                      icon: const Icon(Icons.camera_alt, size: 20),
                                      label: Text(l10n.ocrFromImage, style: const TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.secondary,
                                        side: BorderSide(color: AppColors.secondary),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            ..._selectedTemplate!.fields.map((field) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: CredentialFormField(
                                  field: field,
                                  controller: _controllers[field.key],
                                  value: _fieldValues[field.key],
                                  errorText: _fieldErrors[field.key],
                                  onChanged: (value) {
                                    _fieldValues[field.key] = value;
                                    if (_fieldErrors.containsKey(field.key)) {
                                      setState(() {
                                        _fieldErrors.remove(field.key);
                                      });
                                    }
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _validateAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.processing,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : Text(
                              l10n.createCredential,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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

class _TemplateCard extends StatelessWidget {
  final CredentialTemplate template;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(template.icon, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }
}

