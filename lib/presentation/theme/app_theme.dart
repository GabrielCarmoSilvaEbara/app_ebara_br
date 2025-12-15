// lib/presentation/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: AppTextStyles.fontFamily,

      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundSecondary,

      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        onPrimary: AppColors.textSecondaryDecoration,
        background: AppColors.background,
        surface: AppColors.backgroundCard,
        onSurface: AppColors.textPrimary,
        error: Colors.red,
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.text,
        displayMedium: AppTextStyles.text1,
        labelLarge: AppTextStyles.text2,
        labelMedium: AppTextStyles.text3,
        labelSmall: AppTextStyles.text4,
      ),
    );
  }
}
