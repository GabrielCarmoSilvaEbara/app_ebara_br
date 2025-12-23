import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,

      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundSecondary,

      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textSecondaryDecoration,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: AppColors.backgroundCard,
        onSurface: AppColors.textPrimary,
        surfaceContainer: AppColors.background,
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
