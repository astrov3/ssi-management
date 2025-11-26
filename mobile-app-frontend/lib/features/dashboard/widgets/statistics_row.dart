import 'package:flutter/material.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/features/dashboard/widgets/stat_card.dart';

class StatisticsRow extends StatelessWidget {
  const StatisticsRow({
    super.key,
    required this.vcCount,
    required this.verifiedCount,
  });

  final int vcCount;
  final int verifiedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.statistics,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.credentials,
                value: vcCount.toString(),
                icon: Icons.card_membership,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: l10n.verified,
                value: verifiedCount.toString(),
                icon: Icons.verified,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

