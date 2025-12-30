import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundSecondary,
      dividerColor: Colors.grey.shade200,
      cardColor: AppColors.backgroundCard,
      colorScheme: const ColorScheme(
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
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textSecondaryDecoration,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textDecoration,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: Colors.grey.shade800,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: Color(0xFF1E1E1E),
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.black,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        surfaceContainer: Color(0xFF2C2C2C),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: Colors.white),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: Colors.white,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: Colors.white70),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: Colors.white70),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: Colors.white60),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}
