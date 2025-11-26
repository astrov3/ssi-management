import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ssi_app/app/app.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/app/theme/app_gradients.dart';
import 'package:ssi_app/core/widgets/glass_container.dart';
import 'package:ssi_app/features/auth/authenticate/view/authenticate_screen.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/auth/auth_service.dart';
import 'package:ssi_app/services/localization/language_service.dart';
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
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final isAvailable = await _authService.isBiometricAvailable();
    final isEnabled = await _authService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
        _isBiometricEnabled = isEnabled;
      });
    }
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
      builder: (context) => _WalletInfoDialog(
        address: _address,
      ),
    );
  }

  void _showBackupKeys() {
    showDialog<void>(
      context: context,
      builder: (context) => _BackupKeysDialog(mnemonic: _mnemonic),
    );
  }

  void _showEditNameDialog() {
    final nameController = TextEditingController(text: _walletName);
    showDialog<void>(
      context: context,
      builder: (context) => _EditNameDialog(
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
      builder: (context) => _LanguageDialog(),
    );
  }

  void _showSecuritySettings() {
    showDialog<void>(
      context: context,
      builder: (context) => _SecuritySettingsDialog(
        authService: _authService,
        isBiometricAvailable: _isBiometricAvailable,
        isBiometricEnabled: _isBiometricEnabled,
        onBiometricChanged: () {
          _checkBiometricStatus();
        },
      ),
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
                      _ProfileHeader(
                        address: _address,
                        walletName: _walletName,
                        onEditName: _showEditNameDialog,
                      ),
                      const SizedBox(height: 32),
                      _ProfileOption(
                        icon: Icons.account_circle_outlined,
                        title: AppLocalizations.of(context)!.walletInfo,
                        onTap: _showWalletInfo,
                      ),
                      _ProfileOption(
                        icon: Icons.edit_outlined,
                        title: AppLocalizations.of(context)!.changeWalletName,
                        onTap: _showEditNameDialog,
                      ),
                      _ProfileOption(
                        icon: Icons.vpn_key_outlined,
                        title: AppLocalizations.of(context)!.backupKeys,
                        onTap: _showBackupKeys,
                      ),
                      _ProfileOption(
                        icon: Icons.language,
                        title: AppLocalizations.of(context)!.language,
                        onTap: _showLanguageDialog,
                      ),
                      _ProfileOption(
                        icon: Icons.security_outlined,
                        title: AppLocalizations.of(context)!.security,
                        onTap: _showSecuritySettings,
                      ),
                      _ProfileOption(icon: Icons.history_outlined, title: AppLocalizations.of(context)!.transactionHistory, badge: AppLocalizations.of(context)!.soon),
                      _ProfileOption(icon: Icons.settings_outlined, title: AppLocalizations.of(context)!.settings, badge: AppLocalizations.of(context)!.soon),
                      _ProfileOption(icon: Icons.help_outline, title: AppLocalizations.of(context)!.help, badge: AppLocalizations.of(context)!.soon),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.address,
    required this.walletName,
    required this.onEditName,
  });

  final String address;
  final String walletName;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 60, color: Colors.grey[900]),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                walletName.isNotEmpty ? walletName : address,
            style: TextStyle(
              fontSize: walletName.isNotEmpty ? 22 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.secondary, size: 20),
              onPressed: onEditName,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        if (walletName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            address.length > 10
                ? '${address.substring(0, 6)}...${address.substring(address.length - 6)}'
                : address,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[900],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletInfoDialog extends StatelessWidget {
  const _WalletInfoDialog({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: AppColors.secondary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.walletInfo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InfoRow(label: AppLocalizations.of(context)!.walletAddress, value: address, canCopy: true),
              _InfoRow(label: AppLocalizations.of(context)!.network, value: AppLocalizations.of(context)!.sepoliaTestnet),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.doNotShareThisInfo,
                        style: const TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
        ),
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
                  value.length > 42 ? '${value.substring(0, 10)}...${value.substring(value.length - 10)}' : value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: value.startsWith('0x') ? 'Courier' : null,
                  ),
                ),
              ),
              if (canCopy)
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.secondary, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    final l10n = AppLocalizations.of(context)!;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.addressCopied),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 1),
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

class _EditNameDialog extends StatelessWidget {
  const _EditNameDialog({
    required this.nameController,
    required this.address,
    required this.onSave,
  });

  final TextEditingController nameController;
  final String address;
  final void Function(String name) onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.changeWalletNameTitle, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: l10n.walletName,
              hintText: l10n.enterWalletName,
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.secondary),
              ),
            ),
            autofocus: true,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.address}: ${address.substring(0, 6)}...${address.substring(address.length - 4)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            onSave(nameController.text.trim());
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _BackupKeysDialog extends StatelessWidget {
  const _BackupKeysDialog({required this.mnemonic});

  final String mnemonic;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.vpn_key, color: AppColors.danger, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.backupKeysTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.importantSaveInfo,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (mnemonic.isNotEmpty) ...[
                Text(
                  AppLocalizations.of(context)!.recoveryPhrase,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GlassContainer(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          mnemonic,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Courier',
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppColors.secondary),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: mnemonic));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.mnemonicCopied),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                GlassContainer(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  child: Text(
                    AppLocalizations.of(context)!.mnemonicNotAvailable,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageDialog extends StatelessWidget {
  const _LanguageDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);
    
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.selectLanguage, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: LanguageService.supportedLocales.map((locale) {
          final isSelected = locale.languageCode == currentLocale.languageCode;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.secondary : Colors.white54,
            ),
            title: Text(
              LanguageService.getLocaleDisplayName(locale),
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () {
              SSIApp.of(context)?.setLocale(locale);
              Navigator.pop(context);
            },
          );
        }).toList(),
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


