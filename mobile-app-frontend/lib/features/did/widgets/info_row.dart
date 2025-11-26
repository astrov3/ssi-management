import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssi_app/app/theme/app_colors.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.canCopy = false,
  });

  final String label;
  final String value;
  final bool canCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value.length > 42 ? '${value.substring(0, 20)}...${value.substring(value.length - 10)}' : value,
                  style: TextStyle(color: Colors.grey[900], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canCopy)
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.secondary, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

