import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/features/dashboard/widgets/quick_action_tile.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.orgId,
    this.isOwnerOnChain = false,
    this.isAdmin = false,
    this.isVerifier = false,
    this.onRegister,
    required this.onIssue,
    this.onManageDID,
    this.onAdminPanel,
  });

  final String orgId;
  final bool isOwnerOnChain;
  final bool isAdmin;
  final bool isVerifier;
  final VoidCallback? onRegister;
  final VoidCallback onIssue;
  final VoidCallback? onManageDID;
  final VoidCallback? onAdminPanel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 16),
        if (onManageDID != null)
          QuickActionTile(
            title: l10n.manageDid,
            subtitle: l10n.viewAndManageYourDid,
            icon: Icons.badge,
            iconColor: AppColors.secondary,
            onTap: onManageDID!,
          ),
        QuickActionTile(
          title: l10n.issueCredential,
          subtitle: l10n.createAndIssueNewVC,
          icon: Icons.add_card,
          iconColor: const Color(0xFF3B82F6),
          onTap: onIssue,
        ),
        if (onRegister != null)
          QuickActionTile(
            title: l10n.registerDid,
            subtitle: isOwnerOnChain 
                ? 'You are an owner. Register or manage your DID.'
                : l10n.registerDidOnBlockchain,
            icon: Icons.person_add,
            iconColor: AppColors.secondary,
            onTap: onRegister!,
          ),
        if (onAdminPanel != null)
          QuickActionTile(
            title: 'Admin Panel',
            subtitle: 'Manage trusted verifiers',
            icon: Icons.admin_panel_settings,
            iconColor: Colors.orange,
            onTap: onAdminPanel!,
          ),
      ],
    );
  }
}

