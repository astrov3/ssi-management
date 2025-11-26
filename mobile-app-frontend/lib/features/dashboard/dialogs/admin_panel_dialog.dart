import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class AdminPanelDialog extends StatefulWidget {
  const AdminPanelDialog({
    super.key,
    required this.onSubmit,
  });

  final void Function(String verifierAddress, bool isAdding) onSubmit;

  @override
  State<AdminPanelDialog> createState() => _AdminPanelDialogState();
}

class _AdminPanelDialogState extends State<AdminPanelDialog> {
  final _verifierAddressController = TextEditingController();
  bool _isAdding = true;

  @override
  void dispose() {
    _verifierAddressController.dispose();
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
              TextField(
                controller: _verifierAddressController,
                decoration: InputDecoration(
                  labelText: l10n.verifierAddress,
                  hintText: '0x...',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
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
              widget.onSubmit(_verifierAddressController.text.trim(), _isAdding);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(_isAdding ? l10n.addVerifier : l10n.removeVerifier),
          ),
        ],
      ),
    );
  }
}

