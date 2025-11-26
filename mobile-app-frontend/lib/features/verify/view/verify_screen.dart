import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/core/utils/navigation_utils.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:ssi_app/features/qr/display/qr_display_screen.dart';
import 'package:ssi_app/features/qr/scanner/qr_scanner_screen.dart';
import 'package:ssi_app/features/verify/view/verification_requests_screen.dart';
import 'package:ssi_app/features/credentials/models/credential_models.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _web3Service = Web3Service();
  final _walletConnectService = WalletConnectService();
  final _pinataService = PinataService();
  String _address = '';
  bool _isTrustedVerifier = false;
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _credentials = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (!refresh) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      String? address = await _web3Service.loadWallet();
      address ??= await _walletConnectService.getStoredAddress();

      bool isTrusted = false;
      List<Map<String, dynamic>> credentials = [];
      List<Map<String, dynamic>> pending = [];

      if (address != null && address.isNotEmpty) {
        credentials = await _web3Service.getVCs(address);
        credentials = await _hydrateCredentialSummaries(credentials);

        try {
          isTrusted = await _web3Service.isTrustedVerifier(address);
        } catch (e) {
          debugPrint('[VerifyScreen] Error checking trusted verifier: $e');
        }

        if (isTrusted) {
          try {
            pending = await _web3Service.getAllVerificationRequests(onlyPending: true);
          } catch (e) {
            debugPrint('[VerifyScreen] Error loading requests: $e');
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _address = address ?? '';
        _isTrustedVerifier = isTrusted;
        _credentials = credentials;
        _pendingRequests = pending;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint('[VerifyScreen] Error loading data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _hydrateCredentialSummaries(
    List<Map<String, dynamic>> credentials,
  ) async {
    if (credentials.isEmpty) return credentials;

    final futures = credentials.map((credential) async {
      final enriched = Map<String, dynamic>.from(credential);
      final uri = credential['uri'] as String?;

      if (uri == null || uri.isEmpty) {
        return enriched;
      }

      try {
        final doc = await _pinataService.getJSON(uri);
        final title = _extractTitleFromDocument(doc);
        if (title != null) {
          enriched['title'] = title;
        }
        final type = _extractTypeFromDocument(doc);
        if (type != null) {
          enriched['vcType'] = type;
        }
      } catch (e) {
        debugPrint('[VerifyScreen] Error hydrating credential metadata for $uri: $e');
      }

      return enriched;
    }).toList();

    return Future.wait(futures);
  }

  String? _extractTitleFromDocument(Map<String, dynamic> doc) {
    final directTitle = doc['name'];
    if (directTitle is String && directTitle.trim().isNotEmpty) {
      return directTitle.trim();
    }

    final subject = doc['credentialSubject'];
    if (subject is Map<String, dynamic>) {
      final subjectTitle = subject['credentialName'] ??
          subject['credentialType'] ??
          subject['name'] ??
          subject['fullName'];
      if (subjectTitle is String && subjectTitle.trim().isNotEmpty) {
        return subjectTitle.trim();
      }
    }
    return null;
  }

  String? _extractTypeFromDocument(Map<String, dynamic> doc) {
    final typeData = doc['type'];
    if (typeData is List) {
      for (final entry in typeData.reversed) {
        final value = entry?.toString();
        if (value != null && value.isNotEmpty && value != 'VerifiableCredential') {
          return value;
        }
      }
    } else if (typeData is String && typeData.isNotEmpty && typeData != 'VerifiableCredential') {
      return typeData;
    }
    return null;
  }

  String _getCredentialTitle(Map<String, dynamic> credential, BuildContext context) {
    final vcType = credential['vcType'] as String?;
    if (vcType != null) {
      final typeMetadata = credentialTypeMetadata[vcType];
      if (typeMetadata != null) {
        return typeMetadata.title;
      }
    }

    final customTitle = credential['title']?.toString();
    if (customTitle != null && customTitle.trim().isNotEmpty) {
      return customTitle.trim();
    }

    final index = credential['index'];
    final l10n = AppLocalizations.of(context)!;
    return '${l10n.credentials} #${index ?? '?'}';
  }

  Future<void> _openVerificationRequestsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const VerificationRequestsScreen()),
    );
    if (mounted) {
      _loadData(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.verification,
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.grey[900],
            tooltip: 'Refresh',
            onPressed: _isRefreshing ? null : () => _loadData(refresh: true),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
            : RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () => _loadData(refresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    _QuickActionRow(
                      isLoading: _address.isEmpty && _credentials.isEmpty,
                      credentialsCount: _credentials.length,
                      pendingCount: _pendingRequests.length,
                      onShowQr: _handleShowMyQr,
                      onScan: _showVerifyDialog,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 24),
                    _buildAddressSection(l10n),
                    const SizedBox(height: 24),
                    _buildVerificationQueueSection(l10n),
                    const SizedBox(height: 24),
                    _buildManualVerifyCard(l10n),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAddressSection(AppLocalizations l10n) {
    if (_address.isEmpty) {
      return _InfoBanner(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.walletAddress,
        message: 'Kết nối ví hoặc WalletConnect để hiển thị mã QR.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.walletAddress,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _AddressChip(address: _address),
      ],
    );
  }

  Widget _buildVerificationQueueSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Danh sách chờ xác thực',
              style: TextStyle(
                color: Colors.grey[900],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            if (_isTrustedVerifier)
              TextButton(
                onPressed: _pendingRequests.isEmpty ? null : _openVerificationRequestsScreen,
                child: const Text('Xem tất cả'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_isTrustedVerifier)
          _InfoBanner(
            icon: Icons.verified_outlined,
            title: 'Bạn chưa là trusted verifier',
            message: 'Chỉ trusted verifier mới nhìn thấy và xử lý các yêu cầu xác thực.',
          )
        else if (_pendingRequests.isEmpty)
          _InfoBanner(
            icon: Icons.inbox_outlined,
            title: 'Không có yêu cầu xác thực',
            message: 'Khi có yêu cầu mới, chúng sẽ hiển thị tại đây để bạn xử lý nhanh.',
          )
        else
          Column(
            children: [
              for (final request in _pendingRequests.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PendingRequestTile(
                    request: request,
                    onTap: _openVerificationRequestsScreen,
                  ),
                ),
              if (_pendingRequests.length > 3)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '+${_pendingRequests.length - 3} yêu cầu khác',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildManualVerifyCard(AppLocalizations l10n) {
    return Card(
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_document, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.manualInput,
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Nhập orgID, VC index và hash để xác thực thủ công khi không thể quét QR.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showManualVerifyDialog,
                icon: const Icon(Icons.keyboard),
                label: Text(l10n.verifyVC),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShowMyQr() async {
    if (_address.isEmpty) {
      _showMessage('Chưa tìm thấy địa chỉ ví. Vui lòng mở ví trước.');
      return;
    }
    if (_credentials.isEmpty) {
      _showMessage(AppLocalizations.of(context)!.noCredentials);
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CredentialPickerSheet(
        credentials: _credentials,
      ),
    );

    if (selected == null || !mounted) return;
    _showCredentialQrDialog(selected);
  }

  void _showCredentialQrDialog(Map<String, dynamic> credential) {
    final qrPayload = {
      'type': 'VC',
      'orgID': _address,
      'index': credential['index'],
      'hashCredential': credential['hashCredential'],
      'uri': credential['uri'],
      'issuer': credential['issuer'],
    };
    final qrString = jsonEncode(qrPayload);
    final isVerified = credential['verified'] == true;
    final isValid = credential['valid'] != false;

    showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final credentialTitle = _getCredentialTitle(credential, context);
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '${l10n.myQrCode} - $credentialTitle',
            style: TextStyle(color: Colors.grey[900]),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: qrString,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatusChip(
                      label: isValid ? l10n.valid : l10n.revoked,
                      color: isValid ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: isVerified ? 'Verified' : 'Unverified',
                      color: isVerified ? AppColors.success : Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QRDisplayScreen(qrData: qrPayload),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Xem chi tiết'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  void _showVerifyDialog() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      // Navigate to display screen with scanned data
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QRDisplayScreen(qrData: result),
        ),
      );
    }
  }

  void _showManualVerifyDialog() {
    final orgIDController = TextEditingController();
    final indexController = TextEditingController();
    final hashController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => _ManualVerifyDialog(
        orgIDController: orgIDController,
        indexController: indexController,
        hashController: hashController,
        onSubmit: (orgId, index, hash) {
          Navigator.pop(context);
          _verifyVC(orgId, index, hash);
        },
      ),
    );
  }

  Future<void> _verifyVC(String orgID, int index, String hash) async {
    try {
      _showBlockingSpinner();
      final isValid = await _web3Service.verifyVC(orgID, index, hash);
      NavigationUtils.safePopDialog(mounted ? context : null);
      if (!mounted) return;
      _showVerificationResult(isValid);
    } catch (e) {
      // Safely dismiss dialog even if context is invalid (e.g., returning from Metamask)
      NavigationUtils.safePopDialog(mounted ? context : null);
      
      // Clear pending flags if transaction was rejected
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        _walletConnectService.clearPendingFlags();
      }
      
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      
      // Provide user-friendly error message
      String errorMessage = l10n.verificationError(e.toString());
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        errorMessage = 'Xác thực đã bị hủy trong ví. Vui lòng thử lại.';
      } else if (e.toString().toLowerCase().contains('timeout')) {
        errorMessage = 'Yêu cầu xác thực đã hết thời gian. Vui lòng thử lại.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showVerificationResult(bool isValid) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.cancel,
              color: isValid ? AppColors.success : AppColors.danger,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              isValid ? l10n.valid : l10n.invalid,
              style: TextStyle(
                color: isValid ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          isValid ? l10n.credentialVerified : l10n.credentialInvalid,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? AppColors.success : AppColors.danger,
            ),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showBlockingSpinner() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );
  }
}
class _AddressChip extends StatelessWidget {
  const _AddressChip({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Text(
        address.isNotEmpty
            ? '${address.substring(0, 6)}...${address.substring(address.length - 6)}'
            : AppLocalizations.of(context)?.loading ?? 'Loading...',
        style: TextStyle(
          color: AppColors.secondary,
          fontSize: 14,
          fontFamily: 'Courier',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.isLoading,
    required this.credentialsCount,
    required this.pendingCount,
    required this.onShowQr,
    required this.onScan,
    required this.l10n,
  });

  final bool isLoading;
  final int credentialsCount;
  final int pendingCount;
  final VoidCallback onShowQr;
  final VoidCallback onScan;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.qr_code_2,
            label: l10n.myQrCode,
            description: isLoading
                ? l10n.loading
                : credentialsCount == 0
                    ? l10n.noCredentials
                    : '$credentialsCount credential(s)',
            onTap: onShowQr,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.qr_code_scanner,
            label: l10n.scanQr,
            description: pendingCount > 0 ? '$pendingCount yêu cầu liên quan' : l10n.verifyVC,
            onTap: onScan,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestTile extends StatelessWidget {
  const _PendingRequestTile({
    required this.request,
    required this.onTap,
  });

  final Map<String, dynamic> request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final orgID = request['orgID']?.toString() ?? '';
    final vcIndex = request['vcIndex']?.toString() ?? '0';
    final requestedAt = request['requestedAt'] as int? ?? 0;
    final targetVerifier = request['targetVerifier']?.toString();

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          'VC #$vcIndex',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _QueueInfoRow(
              icon: Icons.business,
              label: 'OrgID',
              value: _formatAddress(orgID),
            ),
            const SizedBox(height: 4),
            _QueueInfoRow(
              icon: Icons.schedule,
              label: 'Gửi',
              value: _formatRelativeTime(requestedAt),
            ),
            const SizedBox(height: 4),
            _QueueInfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Verifier',
              value: targetVerifier == null ||
                      targetVerifier.isEmpty ||
                      targetVerifier.toLowerCase() ==
                          '0x0000000000000000000000000000000000000000'
                  ? 'Bất kỳ'
                  : _formatAddress(targetVerifier),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  static String _formatAddress(String? address) {
    if (address == null || address.isEmpty) return 'N/A';
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  static String _formatRelativeTime(int timestamp) {
    if (timestamp == 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    }
    return 'Vừa xong';
  }
}

class _QueueInfoRow extends StatelessWidget {
  const _QueueInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialPickerSheet extends StatelessWidget {
  const _CredentialPickerSheet({
    required this.credentials,
  });

  final List<Map<String, dynamic>> credentials;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.myQrCode,
              style: TextStyle(
                color: Colors.grey[900],
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chọn credential muốn chia sẻ',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: credentials.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final credential = credentials[index];
                  final isVerified = credential['verified'] == true;
                  final isValid = credential['valid'] != false;
                  final expiration = credential['expirationDate'] as int? ?? 0;
                  final title = credential['title']?.toString();
                  final vcType = credential['vcType']?.toString();

                  return ListTile(
                    onTap: () => Navigator.pop(context, credential),
                    tileColor: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    title: Text(
                      title?.isNotEmpty == true
                          ? title!
                          : (vcType?.isNotEmpty == true
                              ? vcType!
                              : 'VC #${credential['index']}'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          _buildStatusText(isValid, isVerified),
                          style: TextStyle(
                            color: isValid ? AppColors.success : AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (expiration > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'HSD: ${_formatDate(expiration)}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey[500]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _buildStatusText(bool isValid, bool isVerified) {
    if (!isValid) return 'Đã thu hồi';
    if (isVerified) return 'Đã xác thực';
    return 'Chưa xác thực';
  }

  static String _formatDate(int seconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    final two = (int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}

class _ManualVerifyDialog extends StatelessWidget {
  const _ManualVerifyDialog({
    required this.orgIDController,
    required this.indexController,
    required this.hashController,
    required this.onSubmit,
  });

  final TextEditingController orgIDController;
  final TextEditingController indexController;
  final TextEditingController hashController;
  final void Function(String orgId, int index, String hash) onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.verifyVCTitle, style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogTextField(
              controller: orgIDController,
              label: l10n.organizationId,
              hint: '0x...'
            ),
            const SizedBox(height: 16),
            _DialogTextField(
              controller: indexController,
              label: l10n.vcIndex,
              hint: '0',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _DialogTextField(
              controller: hashController,
              label: l10n.credentialHash,
              hint: '0x...',
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            if (orgIDController.text.isEmpty ||
                indexController.text.isEmpty ||
                hashController.text.isEmpty) {
              return;
            }
            final index = int.tryParse(indexController.text);
            if (index == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.invalidIndex), backgroundColor: AppColors.danger),
              );
              return;
            }
            onSubmit(orgIDController.text, index, hashController.text);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: Text(l10n.verify),
        ),
      ],
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
    );
  }
}

