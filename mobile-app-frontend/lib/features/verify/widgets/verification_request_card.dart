import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';

class VerificationRequestCard extends StatelessWidget {
  const VerificationRequestCard({
    super.key,
    required this.request,
    required this.isTrustedVerifier,
    this.currentAddress,
    required this.onTap,
    this.onCancel,
    this.onVerify,
  });

  final Map<String, dynamic> request;
  final bool isTrustedVerifier;
  final String? currentAddress;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onVerify;

  String _formatAddress(String address) {
    if (address.isEmpty) return '';
    if (address.length < 10) return address;
    // Safe substring: address has at least 10 chars, so 0-6 and length-4 are safe
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  bool _canVerify() {
    if (!isTrustedVerifier) return false;
    
    final targetVerifier = request['targetVerifier'] as String?;
    if (targetVerifier == null || targetVerifier.isEmpty) return true;
    
    // Kiểm tra nếu targetVerifier là zero address (cho phép bất kỳ verifier nào)
    if (targetVerifier.toLowerCase() == '0x0000000000000000000000000000000000000000') {
      return true;
    }
    
    // Chỉ verifier được chỉ định mới có thể verify
    return currentAddress?.toLowerCase() == targetVerifier.toLowerCase();
  }

  bool _canCancel() {
    final requester = request['requester'] as String?;
    return currentAddress?.toLowerCase() == requester?.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final orgID = request['orgID'] as String? ?? 'N/A';
    final vcIndex = request['vcIndex'] as int? ?? 0;
    final requester = request['requester'] as String? ?? 'N/A';
    final targetVerifier = request['targetVerifier'] as String?;
    final requestedAt = request['requestedAt'] as int? ?? 0;
    
    final canVerify = _canVerify();
    final canCancel = _canCancel();
    final isAnyVerifier = targetVerifier == null || 
        targetVerifier.isEmpty || 
        targetVerifier.toLowerCase() == '0x0000000000000000000000000000000000000000';

    return Card(
      color: Colors.grey[50],
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'VC #$vcIndex',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (canVerify)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Có thể xác thực',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.business,
                label: 'OrgID',
                value: _formatAddress(orgID),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.person,
                label: 'Người yêu cầu',
                value: _formatAddress(requester),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: isAnyVerifier ? Icons.public : Icons.verified_user,
                label: isAnyVerifier ? 'Verifier' : 'Verifier chỉ định',
                value: isAnyVerifier 
                    ? 'Bất kỳ verifier nào'
                    : _formatAddress(targetVerifier),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Thời gian yêu cầu',
                value: _formatTimestamp(requestedAt),
              ),
              if (canCancel || canVerify) ...[
                const SizedBox(height: 12),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 8),
                  Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canCancel && onCancel != null)
                      GestureDetector(
                        onTap: () {
                          onCancel?.call();
                        },
                        child: TextButton.icon(
                          onPressed: () {
                            onCancel?.call();
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Hủy'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                          ),
                        ),
                      ),
                    if (canVerify && onVerify != null) ...[
                      if (canCancel && onCancel != null) const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          onVerify?.call();
                        },
                        child: ElevatedButton.icon(
                          onPressed: () {
                            onVerify?.call();
                          },
                          icon: const Icon(Icons.verified, size: 16),
                          label: const Text('Xác thực'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

