import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_gradients.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.address,
    required this.walletName,
    required this.formattedAddress,
    required this.onCopy,
  });

  final String address;
  final String walletName;
  final String formattedAddress;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x806366F1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.identityWallet,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (walletName.isNotEmpty) ...[
            Text(
              walletName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              formattedAddress,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                letterSpacing: 1.0,
                fontFamily: 'Courier',
              ),
            ),
          ] else
            Text(
              formattedAddress,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(l10n.sepoliaTestnet, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

