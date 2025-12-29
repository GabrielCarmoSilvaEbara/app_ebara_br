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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: const Color(0xFF1E1E1E),
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.black,
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,
        surfaceContainer: const Color(0xFF2C2C2C),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.text.copyWith(color: Colors.white),
        displayMedium: AppTextStyles.text1.copyWith(color: Colors.white),
        labelLarge: AppTextStyles.text2.copyWith(color: Colors.white70),
        labelMedium: AppTextStyles.text3.copyWith(color: Colors.white70),
        labelSmall: AppTextStyles.text4.copyWith(color: Colors.white60),
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
