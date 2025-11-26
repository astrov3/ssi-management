import 'package:flutter/material.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/features/credentials/view/credentials_screen.dart';
import 'package:ssi_app/features/dashboard/view/dashboard_screen.dart';
import 'package:ssi_app/features/profile/view/profile_screen.dart';
import 'package:ssi_app/features/verify/view/verify_screen.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _screens = const [
    DashboardScreen(),
    CredentialsScreen(),
    VerifyScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: Colors.grey[600],
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: AppLocalizations.of(context)!.overview,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.card_membership_outlined),
              activeIcon: const Icon(Icons.card_membership),
              label: AppLocalizations.of(context)!.credentials,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.verified_user_outlined),
              activeIcon: const Icon(Icons.verified_user),
              label: AppLocalizations.of(context)!.verification,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
        ),
      ),
    );
  }
}

