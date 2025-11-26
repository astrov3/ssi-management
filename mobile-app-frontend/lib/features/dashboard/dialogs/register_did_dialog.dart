import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class RegisterDidDialog extends StatefulWidget {
  const RegisterDidDialog({
    super.key,
    required this.orgIDController,
    required this.onSubmit,
  });

  final TextEditingController orgIDController;
  final void Function(String orgId, String uri, Map<String, dynamic>? metadata) onSubmit;

  @override
  State<RegisterDidDialog> createState() => _RegisterDidDialogState();
}

class _RegisterDidDialogState extends State<RegisterDidDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _logoPath;
  String? _documentPath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Chọn logo', style: TextStyle(color: Colors.white)),
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
            ],
          ),
        ),
      );

      if (source != null) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024);
        if (image != null) {
          setState(() {
            _logoPath = image.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
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
                    l10n.registerDid,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo danh tính phi tập trung (DID) của bạn',
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
                        if (_tabController.index == 0 && _nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập tên'),
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
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.register,
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
    
    if (_tabController.index == 0) {
      // Form tab
      if (_nameController.text.isNotEmpty) {
        metadata['name'] = _nameController.text.trim();
      }
      if (_descriptionController.text.isNotEmpty) {
        metadata['description'] = _descriptionController.text.trim();
      }
      if (_emailController.text.isNotEmpty) {
        metadata['email'] = _emailController.text.trim();
      }
      if (_websiteController.text.isNotEmpty) {
        metadata['website'] = _websiteController.text.trim();
      }
      if (_addressController.text.isNotEmpty) {
        metadata['address'] = _addressController.text.trim();
      }
      if (_phoneController.text.isNotEmpty) {
        metadata['phone'] = _phoneController.text.trim();
      }
      if (_logoPath != null) {
        metadata['logoPath'] = _logoPath;
      }
    }
    
    if (_documentPath != null) {
      metadata['documentPath'] = _documentPath;
    }
    
    // Return empty URI for now, will be set after upload
    widget.onSubmit(widget.orgIDController.text, '', metadata.isEmpty ? null : metadata);
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
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tên hiển thị *',
              hintText: 'Nhập tên của bạn hoặc tổ chức',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.badge, color: Colors.white.withValues(alpha: 0.6)),
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
              hintText: 'Mô tả về bạn hoặc tổ chức (tùy chọn)',
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
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
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
            controller: _websiteController,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Website',
              hintText: 'https://example.com',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.language, color: Colors.white.withValues(alpha: 0.6)),
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
            controller: _addressController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Địa chỉ',
              hintText: 'Địa chỉ liên hệ (tùy chọn)',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.location_on, color: Colors.white.withValues(alpha: 0.6)),
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
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Số điện thoại',
              hintText: '+84...',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.phone, color: Colors.white.withValues(alpha: 0.6)),
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
          Text(
            'Logo (tùy chọn)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickLogo,
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
                    _logoPath != null ? Icons.check_circle : Icons.image,
                    color: _logoPath != null ? AppColors.success : AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _logoPath != null 
                          ? 'Logo đã chọn: ${_logoPath!.split('/').last}'
                          : 'Chọn logo (JPG, PNG)',
                      style: TextStyle(
                        color: _logoPath != null ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  if (_logoPath != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.danger),
                      onPressed: () {
                        setState(() {
                          _logoPath = null;
                        });
                      },
                    ),
                ],
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
            'Upload tài liệu để đăng ký DID',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn có thể upload file PDF, JSON, hoặc hình ảnh chứa thông tin DID của bạn. Nếu là file JSON, dữ liệu sẽ được tự động trích xuất.',
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
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
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

