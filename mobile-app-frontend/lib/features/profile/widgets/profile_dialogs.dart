import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ssi_app/app/app.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/core/widgets/glass_container.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/auth/auth_service.dart';
import 'package:ssi_app/services/localization/language_service.dart';

class WalletInfoDialog extends StatelessWidget {
  const WalletInfoDialog({super.key, required this.address});

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
                  const Icon(Icons.account_balance_wallet,
                      color: AppColors.secondary, size: 28),
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
              InfoRow(
                label: AppLocalizations.of(context)!.walletAddress,
                value: address,
                canCopy: true,
              ),
              InfoRow(
                label: AppLocalizations.of(context)!.network,
                value: AppLocalizations.of(context)!.sepoliaTestnet,
              ),
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
                    const Icon(Icons.warning,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.doNotShareThisInfo,
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
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

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.canCopy = false,
  });

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
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value.length > 42
                      ? '${value.substring(0, 10)}...${value.substring(value.length - 10)}'
                      : value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: value.startsWith('0x') ? 'Courier' : null,
                  ),
                ),
              ),
              if (canCopy)
                IconButton(
                  icon: const Icon(Icons.copy,
                      color: AppColors.secondary, size: 18),
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

class EditNameDialog extends StatelessWidget {
  const EditNameDialog({
    super.key,
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
      title: Text(
        l10n.changeWalletNameTitle,
        style: const TextStyle(color: Colors.white),
      ),
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
              labelStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              focusedBorder: const UnderlineInputBorder(
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
          child:
              Text(l10n.cancel, style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => onSave(nameController.text.trim()),
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class BackupKeysDialog extends StatelessWidget {
  const BackupKeysDialog({super.key, required this.mnemonic});

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
                  const Icon(Icons.vpn_key,
                      color: AppColors.danger, size: 28),
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
                    const Icon(Icons.security,
                        color: AppColors.danger, size: 20),
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
                              content: Text(
                                AppLocalizations.of(context)!.mnemonicCopied,
                              ),
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
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

class LanguageDialog extends StatelessWidget {
  const LanguageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.selectLanguage,
          style: const TextStyle(color: Colors.white)),
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

class SecuritySettingsDialog extends StatefulWidget {
  const SecuritySettingsDialog({
    super.key,
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
  State<SecuritySettingsDialog> createState() =>
      _SecuritySettingsDialogState();
}

class _SecuritySettingsDialogState extends State<SecuritySettingsDialog> {
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

    setState(() => _isLoading = true);

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
      setState(() => _isLoading = false);
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
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}


