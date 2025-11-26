import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/features/auth/authenticate/view/authenticate_screen.dart';
import 'package:ssi_app/features/profile/widgets/profile_dialogs.dart';
import 'package:ssi_app/features/profile/widgets/profile_header.dart';
import 'package:ssi_app/features/profile/widgets/profile_option.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/auth/auth_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/wallet/wallet_name_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _web3Service = Web3Service();
  final _walletConnectService = WalletConnectService();
  final _walletNameService = WalletNameService();
  final _authService = AuthService();
  String _address = 'Loading...';
  String _mnemonic = '';
  String _walletName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }


  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      // Try to load from Web3Service first (private key wallet)
      String? address = await _web3Service.loadWallet();
      
      // If not found, try WalletConnect service
      if (address == null) {
        debugPrint('[Profile] No private key wallet, checking WalletConnect...');
        address = await _walletConnectService.getStoredAddress();
        debugPrint('[Profile] WalletConnect address: $address');
      }
      
      if (address != null && address.isNotEmpty) {
        // Get wallet name
        final walletName = await _walletNameService.getWalletName(address);
        
        // Get mnemonic if available (only for private key wallets)
        try {
          final privateKeyAddress = await _web3Service.loadWallet();
          if (privateKeyAddress != null && privateKeyAddress == address) {
            final prefs = await SharedPreferences.getInstance();
            final mnemonic = prefs.getString('mnemonic') ?? '';
            if (!mounted) return;
            setState(() {
              _address = address!;
              _mnemonic = mnemonic;
              _walletName = walletName ?? '';
              _isLoading = false;
            });
          } else {
            // WalletConnect wallet - no mnemonic/private key available
            if (!mounted) return;
            setState(() {
              _address = address!;
              _mnemonic = ''; // WalletConnect doesn't provide mnemonic
              _walletName = walletName ?? '';
              _isLoading = false;
            });
          }
        } catch (e) {
          debugPrint('[Profile] Error loading wallet data: $e');
          if (!mounted) return;
          setState(() {
            _address = address!;
            _mnemonic = '';
            _walletName = walletName ?? '';
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        setState(() {
          _address = l10n?.noWalletConnected ?? 'No wallet connected';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Profile] Error loading profile data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.confirmLogout, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.confirmLogoutMessage,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _web3Service.clearWalletData(clearWalletConnect: true);
      } catch (e) {
        debugPrint('[Profile] Error clearing wallet data: $e');
      }

      try {
        await _walletConnectService.disconnect(clearStoredData: true);
      } catch (e) {
        debugPrint('[Profile] Error disconnecting WalletConnect: $e');
      }

      try {
        await _authService.clearAuthData();
      } catch (e) {
        debugPrint('[Profile] Error clearing auth data: $e');
      }


      try {
        await _walletNameService.deleteWalletName(_address);
      } catch (e) {
        debugPrint('[Profile] Error clearing wallet name: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('address');
      await prefs.remove('mnemonic');
      await prefs.remove('privateKey');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthenticateScreen()),
        (_) => false,
      );
    }
  }

  void _showWalletInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => WalletInfoDialog(address: _address),
    );
  }

  void _showBackupKeys() {
    showDialog<void>(
      context: context,
      builder: (context) => BackupKeysDialog(mnemonic: _mnemonic),
    );
  }

  void _showEditNameDialog() {
    final nameController = TextEditingController(text: _walletName);
    showDialog<void>(
      context: context,
      builder: (context) => EditNameDialog(
        nameController: nameController,
        address: _address,
        onSave: (name) async {
          Navigator.pop(context);
          await _walletNameService.saveWalletName(_address, name);
          if (!mounted) return;
          setState(() {
            _walletName = name.trim();
          });
          if (!context.mounted) return;
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.walletNameSaved),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => const LanguageDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
            : RefreshIndicator(
                onRefresh: _loadProfileData,
                color: AppColors.secondary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.profile,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ProfileHeader(
                        address: _address,
                        walletName: _walletName,
                        onEditName: _showEditNameDialog,
                      ),
                      const SizedBox(height: 32),
                      ProfileOption(
                        icon: Icons.account_circle_outlined,
                        title: AppLocalizations.of(context)!.walletInfo,
                        onTap: _showWalletInfo,
                      ),
                      ProfileOption(
                        icon: Icons.edit_outlined,
                        title: AppLocalizations.of(context)!.changeWalletName,
                        onTap: _showEditNameDialog,
                      ),
                      ProfileOption(
                        icon: Icons.vpn_key_outlined,
                        title: AppLocalizations.of(context)!.backupKeys,
                        onTap: _showBackupKeys,
                      ),
                      ProfileOption(
                        icon: Icons.language,
                        title: AppLocalizations.of(context)!.language,
                        onTap: _showLanguageDialog,
                      ),
                      ProfileOption(
                        icon: Icons.security_outlined,
                        title: AppLocalizations.of(context)!.security,
                        badge: AppLocalizations.of(context)!.soon,
                      ),
                      ProfileOption(icon: Icons.history_outlined, title: AppLocalizations.of(context)!.transactionHistory, badge: AppLocalizations.of(context)!.soon),
                      ProfileOption(icon: Icons.settings_outlined, title: AppLocalizations.of(context)!.settings, badge: AppLocalizations.of(context)!.soon),
                      ProfileOption(icon: Icons.help_outline, title: AppLocalizations.of(context)!.help, badge: AppLocalizations.of(context)!.soon),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.danger, width: 1.5),
                          ),
                          child: ElevatedButton(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.logout,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _SecuritySettingsDialog extends StatefulWidget {
  const _SecuritySettingsDialog({
    required this.authService,
    required this.isBiometricAvailable,
    required this.isBiometricEnabled,
    required this.onBiometricChanged,
  });

  final AuthService authService;
  final bool isBiometricAvailable;
  final bool isBiometricEnabled;
  final VoidCallback onBiometricChanged;

  @override
  State<_SecuritySettingsDialog> createState() => _SecuritySettingsDialogState();
}

class _SecuritySettingsDialogState extends State<_SecuritySettingsDialog> {
  bool _isBiometricEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isBiometricEnabled = widget.isBiometricEnabled;
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!widget.isBiometricAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.biometricNotAvailable),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (value) {
        await widget.authService.enableBiometric();
      } else {
        await widget.authService.disableBiometric();
      }

      if (!mounted) return;
      setState(() {
        _isBiometricEnabled = value;
        _isLoading = false;
      });

      widget.onBiometricChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        l10n.security,
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isBiometricAvailable) ...[
            SwitchListTile(
              value: _isBiometricEnabled,
              onChanged: _isLoading ? null : _toggleBiometric,
              title: Text(
                l10n.enableBiometric,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                l10n.biometricDescription,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              activeThumbColor: AppColors.secondary,
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.fingerprint, color: Colors.white54),
              title: Text(
                l10n.enableBiometric,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                l10n.biometricNotAvailable,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
          ),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}


