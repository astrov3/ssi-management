import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_gradients.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
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
              icon: const Icon(Icons.edit, color: Colors.deepPurpleAccent, size: 20),
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


