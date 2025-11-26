import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class AuthorizeIssuerDialog extends StatelessWidget {
  const AuthorizeIssuerDialog({
    super.key,
    required this.issuerController,
  });

  final TextEditingController issuerController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.authorizeIssuer, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: issuerController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: l10n.issuerAddress,
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
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: Text(l10n.authorize),
        ),
      ],
    );
  }
}

