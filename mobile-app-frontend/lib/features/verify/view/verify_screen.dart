import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/app/theme/app_gradients.dart';
import 'package:ssi_app/core/utils/navigation_utils.dart';
import 'package:ssi_app/features/qr/display/qr_display_screen.dart';
import 'package:ssi_app/features/qr/scanner/qr_scanner_screen.dart';
import 'package:ssi_app/features/verify/view/verification_requests_screen.dart';
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
  String _address = '';
  bool _isTrustedVerifier = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAddress() async {
    String? address = await _web3Service.loadWallet();
    address ??= await _walletConnectService.getStoredAddress();
    
    if (address != null && mounted) {
      setState(() => _address = address!);
      // Kiểm tra xem có phải trusted verifier không
      final isTrusted = await _web3Service.isTrustedVerifier(address);
      if (mounted) {
        setState(() => _isTrustedVerifier = isTrusted);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _QrCard(address: _address),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          AppLocalizations.of(context)!.myQrCode,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            AppLocalizations.of(context)!.shareQrCodeMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _AddressChip(address: _address),
                        const SizedBox(height: 40),
                        _OutlinedButton(
                          icon: Icons.qr_code_scanner,
                          label: AppLocalizations.of(context)!.verifyVC,
                          onPressed: _showVerifyDialog,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.or,
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        _GradientButton(
                          icon: Icons.edit,
                          label: AppLocalizations.of(context)!.manualInput,
                          onPressed: _showManualVerifyDialog,
                        ),
                        if (_isTrustedVerifier) ...[
                          const SizedBox(height: 24),
                          Divider(color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          _OutlinedButton(
                            icon: Icons.list_alt,
                            label: 'Danh sách chờ xác thực',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const VerificationRequestsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

class _QrCard extends StatelessWidget {
  const _QrCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: address.isNotEmpty
          ? QrImageView(
              data: address,
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
            )
          : const SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
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

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary, width: 2),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x806366F1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
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

