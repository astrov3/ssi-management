import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(l10n.loadingData, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }
}

