import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 16),
          Text('Đang tải dữ liệu...', style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }
}

