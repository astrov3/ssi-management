import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ssi_app/app/theme/app_colors.dart';

class UpdateDIDDialog extends StatefulWidget {
  const UpdateDIDDialog({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.emailController,
    required this.websiteController,
    required this.addressController,
    required this.phoneController,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController emailController;
  final TextEditingController websiteController;
  final TextEditingController addressController;
  final TextEditingController phoneController;

  @override
  State<UpdateDIDDialog> createState() => _UpdateDIDDialogState();
}

class _UpdateDIDDialogState extends State<UpdateDIDDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      // Use rootNavigator to prevent closing the main dialog
      final source = await showDialog<ImageSource>(
        context: context,
        useRootNavigator: true,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Chọn logo', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
                title: const Text('Chụp ảnh', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context, rootNavigator: true).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.secondary),
                title: const Text('Chọn từ thư viện', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context, rootNavigator: true).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024);
        if (image != null && mounted) {
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
      // FilePicker should not close the dialog, but we ensure mounted check
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'json', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null && mounted) {
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
                  const Text(
                    'Cập nhật DID',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cập nhật thông tin danh tính phi tập trung (DID) của bạn',
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
                  _buildFormTab(),
                  _buildUploadTab(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'tab': _tabController.index,
                          'logoPath': _logoPath,
                          'documentPath': _documentPath,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cập nhật',
                        style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tên hiển thị',
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
            controller: widget.descriptionController,
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
            controller: widget.emailController,
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
            controller: widget.websiteController,
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
            controller: widget.addressController,
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
            controller: widget.phoneController,
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

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload tài liệu để cập nhật DID',
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
          Text(
            'Tài liệu',
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

