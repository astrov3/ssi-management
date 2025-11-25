import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/core/widgets/glass_container.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:ssi_app/services/role/role_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';

class DIDManagementScreen extends StatefulWidget {
  const DIDManagementScreen({super.key});

  @override
  State<DIDManagementScreen> createState() => _DIDManagementScreenState();
}

class _DIDManagementScreenState extends State<DIDManagementScreen> {
  final _web3Service = Web3Service();
  final _roleService = RoleService();
  final _pinataService = PinataService();
  
  String? _currentAddress;
  String? _currentOrgID;
  Map<String, dynamic>? _didData;
  bool _isLoading = true;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _roleService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final address = await _roleService.getCurrentAddress();
      if (address == null || address.isEmpty) {
        if (!mounted) return;
        setState(() {
          _currentAddress = null;
          _isLoading = false;
        });
        return;
      }

      setState(() => _currentAddress = address);
      
      // Use address as default orgID for testing, or allow user to specify
      final orgID = address;
      _currentOrgID = orgID;

      try {
        final did = await _web3Service.getDID(orgID);
        if (did == null) {
          // DID doesn't exist yet
          if (!mounted) return;
          setState(() {
            _didData = null;
            _isOwner = false;
            _isLoading = false;
          });
          return;
        }
        
        final isOwner = await _roleService.isOwnerOf(orgID, address);
        
        if (!mounted) return;
        setState(() {
          _didData = did;
          _isOwner = isOwner;
          _isLoading = false;
        });
      } catch (_) {
        // Error occurred
        if (!mounted) return;
        setState(() {
          _didData = null;
          _isOwner = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading DID data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerDID() async {
    if (_currentAddress == null) {
      _showError('Không tìm thấy địa chỉ ví');
      return;
    }

    final orgIDController = TextEditingController(text: _currentAddress);
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _RegisterDIDDialog(
        orgIDController: orgIDController,
        nameController: nameController,
        descriptionController: descriptionController,
      ),
    );

    if (confirmed != true) return;

    try {
      _showBlockingSpinner('Đang tạo DID document và upload lên IPFS...');

      // Create DID document
      final metadata = <String, dynamic>{};
      if (nameController.text.isNotEmpty) {
        metadata['name'] = nameController.text.trim();
      }
      if (descriptionController.text.isNotEmpty) {
        metadata['description'] = descriptionController.text.trim();
      }

      final didDocument = _pinataService.createDIDDocument(
        id: 'did:ethr:${orgIDController.text}',
        controller: _currentAddress!,
        serviceEndpoint: 'https://ssi.example.com',
        metadata: metadata.isEmpty ? null : metadata,
      );

      // Upload to IPFS
      final ipfsUri = await _pinataService.uploadJSON(didDocument);
      final hashData = _pinataService.generateHash(didDocument);

      // Check if using WalletConnect
      final walletConnectService = WalletConnectService();
      final isWC = await walletConnectService.isConnected();
      
      if (isWC) {
        // Update spinner message for WalletConnect transaction
        _updateSpinnerMessage('Đang gửi transaction đến MetaMask...\n\nVui lòng mở MetaMask wallet và xác nhận transaction.\n\nNếu không thấy notification, vui lòng mở MetaMask app thủ công.');
      } else {
        _updateSpinnerMessage('Đang đăng ký DID trên blockchain...');
      }

      // Register DID on blockchain
      final txHash = await _web3Service.registerDID(orgIDController.text, hashData, ipfsUri);

      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showSuccess('DID đã được đăng ký thành công!\nTransaction: ${txHash.substring(0, 10)}...');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      
      // Provide more helpful error messages
      String errorMessage = 'Lỗi đăng ký DID: $e';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Transaction timeout. Vui lòng kiểm tra MetaMask wallet và xác nhận transaction, sau đó thử lại.';
      } else if (e.toString().contains('rejected') || e.toString().contains('denied')) {
        errorMessage = 'Transaction đã bị từ chối trong MetaMask wallet.';
      } else if (e.toString().contains('session') && e.toString().contains('disconnected')) {
        errorMessage = 'WalletConnect session đã bị ngắt kết nối. Vui lòng kết nối lại wallet.';
      }
      
      _showError(errorMessage);
    }
  }

  Future<void> _updateDID() async {
    if (_currentOrgID == null || !_isOwner) {
      _showError('Bạn không có quyền cập nhật DID này');
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _UpdateDIDDialog(
        nameController: nameController,
        descriptionController: descriptionController,
      ),
    );

    if (confirmed != true) return;

    try {
      _showBlockingSpinner('Đang cập nhật DID document...');

      // Create updated DID document
      final metadata = <String, dynamic>{};
      if (nameController.text.isNotEmpty) {
        metadata['name'] = nameController.text.trim();
      }
      if (descriptionController.text.isNotEmpty) {
        metadata['description'] = descriptionController.text.trim();
      }

      final didDocument = _pinataService.createDIDDocument(
        id: 'did:ethr:$_currentOrgID',
        controller: _currentAddress!,
        serviceEndpoint: 'https://ssi.example.com',
        metadata: metadata.isEmpty ? null : metadata,
      );

      // Upload to IPFS
      final ipfsUri = await _pinataService.uploadJSON(didDocument);
      final hashData = _pinataService.generateHash(didDocument);

      // Update DID on blockchain
      await _web3Service.updateDID(_currentOrgID!, hashData, ipfsUri);

      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showSuccess('DID đã được cập nhật thành công!');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showError('Lỗi cập nhật DID: $e');
    }
  }

  Future<void> _deactivateDID() async {
    if (_currentOrgID == null || !_isOwner) {
      _showError('Bạn không có quyền vô hiệu hóa DID này');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xác nhận vô hiệu hóa DID', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc chắn muốn vô hiệu hóa DID này? Sau khi vô hiệu hóa, bạn sẽ không thể phát hành VC mới.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _showBlockingSpinner('Đang vô hiệu hóa DID...');
      await _web3Service.deactivateDID(_currentOrgID!);

      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showSuccess('DID đã được vô hiệu hóa');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showError('Lỗi vô hiệu hóa DID: $e');
    }
  }

  Future<void> _authorizeIssuer() async {
    if (_currentOrgID == null || !_isOwner) {
      _showError('Bạn không có quyền ủy quyền issuer');
      return;
    }

    final issuerController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _AuthorizeIssuerDialog(
        issuerController: issuerController,
      ),
    );

    if (confirmed != true) return;

    final issuerAddress = issuerController.text.trim();
    if (!_isValidAddress(issuerAddress)) {
      _showError('Địa chỉ issuer không hợp lệ');
      return;
    }

    try {
      _showBlockingSpinner('Đang ủy quyền issuer...');
      await _web3Service.authorizeIssuer(_currentOrgID!, issuerAddress);

      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showSuccess('Issuer đã được ủy quyền thành công!');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      _showError('Lỗi ủy quyền issuer: $e');
    }
  }

  bool _isValidAddress(String address) {
    return address.startsWith('0x') && address.length == 42;
  }

  void _showBlockingSpinner(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            if (message.contains('MetaMask') || message.contains('wallet'))
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Vui lòng mở MetaMask và xác nhận transaction',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _updateSpinnerMessage(String message) {
    // Try to update the existing dialog if possible
    // This is a workaround - ideally we'd use a StatefulBuilder
    Navigator.of(context).pop();
    _showBlockingSpinner(message);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Quản lý DID',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : _currentAddress == null
              ? _buildNoWalletView()
              : _didData == null
                  ? _buildNoDIDView()
                  : _buildDIDView(),
    );
  }

  Widget _buildNoWalletView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wallet_outlined, size: 80, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Chưa kết nối ví',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDIDView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.person_add_outlined, size: 64, color: AppColors.secondary),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có DID',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng ký DID để bắt đầu sử dụng dịch vụ',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _registerDID,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đăng ký DID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDIDView() {
    final owner = _didData!['owner'] as String;
    final uri = _didData!['uri'] as String;
    final active = _didData!['active'] as bool;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DIDInfoCard(
            orgID: _currentOrgID!,
            owner: owner,
            uri: uri,
            active: active,
          ),
          const SizedBox(height: 24),
          if (_isOwner && active) ...[
            _ActionButton(
              icon: Icons.edit,
              label: 'Cập nhật DID',
              color: AppColors.secondary,
              onPressed: _updateDID,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.person_add,
              label: 'Ủy quyền Issuer',
              color: const Color(0xFF3B82F6),
              onPressed: _authorizeIssuer,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.block,
              label: 'Vô hiệu hóa DID',
              color: AppColors.danger,
              onPressed: _deactivateDID,
            ),
          ] else if (!active) ...[
            GlassContainer(
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'DID đã bị vô hiệu hóa',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RegisterDIDDialog extends StatelessWidget {
  const _RegisterDIDDialog({
    required this.orgIDController,
    required this.nameController,
    required this.descriptionController,
  });

  final TextEditingController orgIDController;
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đăng ký DID',
              style: TextStyle(
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
            const SizedBox(height: 24),
            TextField(
              controller: orgIDController,
              enabled: false,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              decoration: InputDecoration(
                labelText: 'Địa chỉ ví (Wallet Address)',
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
              controller: nameController,
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
              controller: descriptionController,
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
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
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Đăng ký DID',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateDIDDialog extends StatelessWidget {
  const _UpdateDIDDialog({
    required this.nameController,
    required this.descriptionController,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Cập nhật DID', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Tên (tùy chọn)',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: const Text('Cập nhật'),
        ),
      ],
    );
  }
}

class _AuthorizeIssuerDialog extends StatelessWidget {
  const _AuthorizeIssuerDialog({required this.issuerController});

  final TextEditingController issuerController;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Ủy quyền Issuer', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: issuerController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Địa chỉ Issuer',
          hintText: '0x...',
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: const Text('Ủy quyền'),
        ),
      ],
    );
  }
}

class _DIDInfoCard extends StatelessWidget {
  const _DIDInfoCard({
    required this.orgID,
    required this.owner,
    required this.uri,
    required this.active,
  });

  final String orgID;
  final String owner;
  final String uri;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.badge, color: AppColors.secondary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DID Information',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (active ? AppColors.success : AppColors.danger).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        active ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: active ? AppColors.success : AppColors.danger,
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
          _InfoRow(label: 'Organization ID', value: orgID, canCopy: true),
          _InfoRow(label: 'Owner', value: owner, canCopy: true),
          _InfoRow(label: 'URI', value: uri, canCopy: true),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.canCopy = false});

  final String label;
  final String value;
  final bool canCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value.length > 42 ? '${value.substring(0, 20)}...${value.substring(value.length - 10)}' : value,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Courier'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canCopy)
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.secondary, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

