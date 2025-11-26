import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class IssueVcDialog extends StatefulWidget {
  const IssueVcDialog({
    super.key,
    required this.orgIDController,
    required this.onSubmit,
  });

  final TextEditingController orgIDController;
  final void Function(String orgId, String uri, Map<String, dynamic>? metadata, String? expirationDate) onSubmit;

  @override
  State<IssueVcDialog> createState() => _IssueVcDialogState();
}

class _IssueVcDialogState extends State<IssueVcDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _typeController = TextEditingController(text: 'Credential');
  final _subjectNameController = TextEditingController();
  final _subjectEmailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expirationDateController = TextEditingController();
  String? _documentPath;
  DateTime? _selectedExpirationDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _typeController.dispose();
    _subjectNameController.dispose();
    _subjectEmailController.dispose();
    _descriptionController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  Future<void> _pickExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
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

    if (picked != null) {
      setState(() {
        _selectedExpirationDate = picked;
        _expirationDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'json', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _documentPath = result.files.single.path!;
        });
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
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.issueCredential,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo và phát hành Verifiable Credential',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.secondary,
              unselectedLabelColor: Colors.white54,
              indicatorColor: AppColors.secondary,
              tabs: const [
                Tab(text: 'Điền form', icon: Icon(Icons.edit)),
                Tab(text: 'Upload tài liệu', icon: Icon(Icons.upload_file)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFormTab(l10n),
                  _buildUploadTab(l10n),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_tabController.index == 0 && _subjectNameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập tên chủ thể'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
                        if (_tabController.index == 1 && _documentPath == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng chọn tài liệu'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
                        _handleSubmit();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.issue,
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

  void _handleSubmit() {
    final metadata = <String, dynamic>{};
    String? expirationDateIso;
    
    if (_tabController.index == 0) {
      // Form tab
      if (_typeController.text.isNotEmpty) {
        metadata['type'] = _typeController.text.trim();
      }
      if (_subjectNameController.text.isNotEmpty) {
        metadata['name'] = _subjectNameController.text.trim();
      }
      if (_subjectEmailController.text.isNotEmpty) {
        metadata['email'] = _subjectEmailController.text.trim();
      }
      if (_descriptionController.text.isNotEmpty) {
        metadata['description'] = _descriptionController.text.trim();
      }
      if (_selectedExpirationDate != null) {
        expirationDateIso = _selectedExpirationDate!.toIso8601String();
      }
    }
    
    if (_documentPath != null) {
      metadata['documentPath'] = _documentPath;
    }
    
    // Return empty URI for now, will be set after upload
    widget.onSubmit(
      widget.orgIDController.text,
      '',
      metadata.isEmpty ? null : metadata,
      expirationDateIso,
    );
    Navigator.pop(context);
  }

  Widget _buildFormTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.orgIDController,
            enabled: false,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            decoration: InputDecoration(
              labelText: l10n.organizationId,
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintText: '0x...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.account_circle, color: Colors.white.withValues(alpha: 0.6)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _typeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Loại Credential *',
              hintText: 'Ví dụ: EducationalCredential, IdentityCredential',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.category, color: Colors.white.withValues(alpha: 0.6)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _subjectNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tên chủ thể *',
              hintText: 'Tên người nhận credential',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.person, color: Colors.white.withValues(alpha: 0.6)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _subjectEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email chủ thể',
              hintText: 'email@example.com',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.email, color: Colors.white.withValues(alpha: 0.6)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Mô tả',
              hintText: 'Mô tả về credential (tùy chọn)',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(Icons.description, color: Colors.white.withValues(alpha: 0.6)),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _expirationDateController,
            readOnly: true,
            onTap: _pickExpirationDate,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Ngày hết hạn (tùy chọn)',
              hintText: 'Chọn ngày hết hạn',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.6)),
              suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.6)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload tài liệu để phát hành VC',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn có thể upload file PDF, JSON, hoặc hình ảnh chứa thông tin credential. Nếu là file JSON, dữ liệu sẽ được tự động trích xuất.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: widget.orgIDController,
            enabled: false,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            decoration: InputDecoration(
              labelText: l10n.organizationId,
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintText: '0x...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.account_circle, color: Colors.white.withValues(alpha: 0.6)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tài liệu *',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDocument,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Icon(
                    _documentPath != null ? Icons.check_circle : Icons.upload_file,
                    color: _documentPath != null ? AppColors.success : AppColors.secondary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _documentPath != null 
                              ? 'Tài liệu đã chọn'
                              : 'Chọn tài liệu (PDF, JSON, JPG, PNG)',
                          style: TextStyle(
                            color: _documentPath != null ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_documentPath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _documentPath!.split('/').last,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_documentPath != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.danger),
                      onPressed: () {
                        setState(() {
                          _documentPath = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lưu ý: File JSON sẽ được tự động parse và trích xuất metadata. File PDF và hình ảnh sẽ được lưu trữ trên IPFS.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

