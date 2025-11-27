import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class AdminPanelDialog extends StatefulWidget {
  const AdminPanelDialog({
    super.key,
    required this.onVerifierSubmit,
    required this.onChangeAdmin,
  });

  final void Function(String verifierAddress, bool isAdding) onVerifierSubmit;
  final void Function(String newAdminAddress) onChangeAdmin;

  @override
  State<AdminPanelDialog> createState() => _AdminPanelDialogState();
}

class _AdminPanelDialogState extends State<AdminPanelDialog> {
  final _verifierAddressController = TextEditingController();
  final _newAdminController = TextEditingController();
  bool _isAdding = true;

  @override
  void dispose() {
    _verifierAddressController.dispose();
    _newAdminController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.adminPanel, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.manageTrustedVerifiers,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _verifierAddressController,
                label: l10n.verifierAddress,
                hint: '0x...',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text(l10n.addEnable, style: const TextStyle(color: Colors.white)),
                      value: true,
                      groupValue: _isAdding,
                      onChanged: (value) => setState(() => _isAdding = value!),
                      activeColor: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text(l10n.removeDisable, style: const TextStyle(color: Colors.white)),
                      value: false,
                      groupValue: _isAdding,
                      onChanged: (value) => setState(() => _isAdding = value!),
                      activeColor: AppColors.danger,
                    ),
                  ),
                ],
              ),
              _buildAdminTransferSection(l10n),
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
              if (_verifierAddressController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseEnterVerifierAddress),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }
              widget.onVerifierSubmit(_verifierAddressController.text.trim(), _isAdding);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(_isAdding ? l10n.addVerifier : l10n.removeVerifier),
          ),
        ],
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildAdminTransferSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32, color: Colors.white24),
        Text(
          l10n.transferAdminTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.transferAdminDescription,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _newAdminController,
          label: l10n.newAdminAddressLabel,
          hint: '0x...',
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            final newAdmin = _newAdminController.text.trim();
            if (newAdmin.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.pleaseEnterNewAdminAddress),
                  backgroundColor: AppColors.danger,
                ),
              );
              return;
            }
            Navigator.pop(context);
            widget.onChangeAdmin(newAdmin);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.swap_horiz),
          label: Text(l10n.updateAdminButton),
        ),
      ],
    );
  }
}

