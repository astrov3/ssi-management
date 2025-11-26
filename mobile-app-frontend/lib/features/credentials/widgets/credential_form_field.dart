import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/features/credentials/models/credential_template.dart';

/// Form field widget for credential fields
class CredentialFormField extends StatelessWidget {
  final CredentialField field;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String? errorText;

  const CredentialFormField({
    super.key,
    required this.field,
    this.controller,
    this.onChanged,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case CredentialFieldType.date:
        return _DateField(
          field: field,
          controller: controller,
          onChanged: onChanged,
          value: value,
          errorText: errorText,
        );
      case CredentialFieldType.dropdown:
        return _DropdownField(
          field: field,
          controller: controller,
          onChanged: onChanged,
          value: value,
          errorText: errorText,
        );
      case CredentialFieldType.file:
        return _FileField(
          field: field,
          onChanged: onChanged,
          value: value,
          errorText: errorText,
        );
      case CredentialFieldType.textarea:
        return _TextAreaField(
          field: field,
          controller: controller,
          onChanged: onChanged,
          value: value,
          errorText: errorText,
        );
      case CredentialFieldType.number:
        return _NumberField(
          field: field,
          controller: controller,
          onChanged: onChanged,
          value: value,
          errorText: errorText,
        );
      case CredentialFieldType.email:
        return _EmailField(
          field: field,
          controller: controller,
          onChanged: onChanged,
          value: value,
          errorText: errorText,
        );
      case CredentialFieldType.phone:
        return _PhoneField(
          field: field,
          controller: controller,
          onChanged: onChanged,
          value: value,
          errorText: errorText,
        );
      default:
        return _TextField(
          field: field,
          controller: controller,
          onChanged: onChanged,
          value: value,
          errorText: errorText,
        );
    }
  }
}

class _TextField extends StatelessWidget {
  final CredentialField field;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String? errorText;

  const _TextField({
    required this.field,
    this.controller,
    this.onChanged,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? TextEditingController(text: value);
    
    return TextField(
      controller: effectiveController,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        hintText: field.placeholder,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        errorText: errorText,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}

class _TextAreaField extends StatelessWidget {
  final CredentialField field;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String? errorText;

  const _TextAreaField({
    required this.field,
    this.controller,
    this.onChanged,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? TextEditingController(text: value);
    
    return TextField(
      controller: effectiveController,
      onChanged: onChanged,
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        hintText: field.placeholder,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        errorText: errorText,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final CredentialField field;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String? errorText;

  const _NumberField({
    required this.field,
    this.controller,
    this.onChanged,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? TextEditingController(text: value);
    
    return TextField(
      controller: effectiveController,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        hintText: field.placeholder,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        errorText: errorText,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  final CredentialField field;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String? errorText;

  const _EmailField({
    required this.field,
    this.controller,
    this.onChanged,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? TextEditingController(text: value);
    
    return TextField(
      controller: effectiveController,
      onChanged: onChanged,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        hintText: field.placeholder,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        errorText: errorText,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final CredentialField field;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String? errorText;

  const _PhoneField({
    required this.field,
    this.controller,
    this.onChanged,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? TextEditingController(text: value);
    
    return TextField(
      controller: effectiveController,
      onChanged: onChanged,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        hintText: field.placeholder,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        errorText: errorText,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}

class _DateField extends StatefulWidget {
  final CredentialField field;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String? errorText;

  const _DateField({
    required this.field,
    this.controller,
    this.onChanged,
    this.value,
    this.errorText,
  });

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  late TextEditingController _controller;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.value != null && widget.value!.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.value!);
        _controller.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      } catch (e) {
        // Invalid date format
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      widget.onChanged?.call(picked.toIso8601String());
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: true,
      onTap: () => _selectDate(context),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: widget.field.label + (widget.field.required ? ' *' : ''),
        hintText: widget.field.placeholder ?? 'Chọn ngày',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        errorText: widget.errorText,
        suffixIcon: Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.6)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final CredentialField field;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String? errorText;

  const _DropdownField({
    required this.field,
    this.controller,
    this.onChanged,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final options = field.options ?? [];
    String? selectedValue = value;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: field.label + (field.required ? ' *' : ''),
        hintText: field.placeholder ?? 'Chọn một lựa chọn',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        errorText: errorText,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger),
        ),
      ),
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: Colors.white),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged?.call(newValue);
          controller?.text = newValue;
        }
      },
    );
  }
}

class _FileField extends StatefulWidget {
  final CredentialField field;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String? errorText;

  const _FileField({
    required this.field,
    this.onChanged,
    this.value,
    this.errorText,
  });

  @override
  State<_FileField> createState() => _FileFieldState();
}

class _FileFieldState extends State<_FileField> {
  String? _fileName;
  File? _file;

  @override
  void initState() {
    super.initState();
    if (widget.value != null && widget.value!.isNotEmpty) {
      _fileName = widget.value;
    }
  }

  Future<void> _pickFile() async {
    try {
      // Show dialog to choose between camera and file picker
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Chọn nguồn', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
                title: const Text('Chụp ảnh', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.secondary),
                title: const Text('Chọn từ thư viện', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: AppColors.secondary),
                title: const Text('Chọn file', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        // Pick image from camera or gallery
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _fileName = image.name;
            _file = File(image.path);
          });
          widget.onChanged?.call(image.path);
        }
      } else {
        // Pick file
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );

        if (result != null && result.files.single.path != null) {
          setState(() {
            _file = File(result.files.single.path!);
            _fileName = result.files.single.name;
          });
          widget.onChanged?.call(result.files.single.path!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn file: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.field.label + (widget.field.required ? ' *' : ''),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _file != null ? Icons.check_circle : Icons.upload_file,
                  color: _file != null ? AppColors.success : AppColors.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fileName ?? widget.field.hint ?? 'Chọn file',
                    style: TextStyle(
                      color: _fileName != null ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (_file != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    onPressed: () {
                      setState(() {
                        _file = null;
                        _fileName = null;
                      });
                      widget.onChanged?.call('');
                    },
                  ),
              ],
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

