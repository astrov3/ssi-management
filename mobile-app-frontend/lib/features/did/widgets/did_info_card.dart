import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/features/did/widgets/info_row.dart';

class DIDInfoCard extends StatelessWidget {
  const DIDInfoCard({
    super.key,
    required this.orgID,
    required this.owner,
    required this.uri,
    required this.active,
  });

  final String orgID;
  final String owner;
  final String uri;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.badge, color: AppColors.secondary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DID Information',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[900]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (active ? AppColors.success : AppColors.danger).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        active ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: active ? AppColors.success : AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          InfoRow(label: 'Organization ID', value: orgID, canCopy: true),
          InfoRow(label: 'Owner', value: owner, canCopy: true),
          InfoRow(label: 'URI', value: uri, canCopy: true),
        ],
      ),
    );
  }
}

