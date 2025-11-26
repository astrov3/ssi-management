import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';

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
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Admin Panel - Manage Trusted Verifiers', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _verifierAddressController,
                decoration: const InputDecoration(
                  labelText: 'Verifier Address *',
                  hintText: '0x...',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Add/Enable', style: TextStyle(color: Colors.white)),
                      value: true,
                      groupValue: _isAdding,
                      onChanged: (value) => setState(() => _isAdding = value!),
                      activeColor: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Remove/Disable', style: TextStyle(color: Colors.white)),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_verifierAddressController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter verifier address'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }
              widget.onSubmit(_verifierAddressController.text.trim(), _isAdding);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(_isAdding ? 'Add Verifier' : 'Remove Verifier'),
          ),
        ],
      ),
    );
  }
}

