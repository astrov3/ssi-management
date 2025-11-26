import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';

class AuthorizeIssuerDialog extends StatelessWidget {
  const AuthorizeIssuerDialog({
    super.key,
    required this.issuerController,
  });

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

