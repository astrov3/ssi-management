import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.secondary],
  );

  static const LinearGradient splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.secondary, AppColors.accentPink],
  );

  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  const AppGradients._();
}

