import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.walletName,
    required this.onNotificationsTap,
  });

  final String walletName;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              walletName.isEmpty ? 'SSI Account' : walletName,
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onNotificationsTap,
          icon: Icon(Icons.notifications_outlined, color: Colors.grey[900]),
        ),
      ],
    );
  }
}

