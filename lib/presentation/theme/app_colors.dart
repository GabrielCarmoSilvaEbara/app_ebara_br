import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF004F9F);
  static const Color primaryVariant = Color(0xFF084B9C);
  static const Color secondary = Color(0xFFF8F9FA);

  static const Color background = Color(0xFF004F9F);
  static const Color backgroundSecondary = Color(0xFFF8F9FA);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundTable = Color(0xF8F9FAFF);

  static const Color textPrimary = Color(0xFF004F9F);
  static const Color textSecondary = Color(0xFF084B9C);
  static const Color textDecoration = Color(0xFF707B81);
  static const Color textSecondaryDecoration = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFFFFFFF);

  static final Color primaryAlpha05 = primary.withValues(alpha: 0.05);
  static final Color primaryAlpha10 = primary.withValues(alpha: 0.1);
  static final Color primaryAlpha20 = primary.withValues(alpha: 0.2);
  static final Color primaryAlpha30 = primary.withValues(alpha: 0.3);

  static const Color onSurface = textPrimary;
  static final Color onSurfaceAlpha05 = textDecoration.withValues(alpha: 0.05);
  static final Color onSurfaceAlpha10 = textDecoration.withValues(alpha: 0.1);
  static final Color onSurfaceAlpha20 = textDecoration.withValues(alpha: 0.2);
  static final Color onSurfaceAlpha30 = textDecoration.withValues(alpha: 0.3);
  static final Color onSurfaceAlpha50 = textDecoration.withValues(alpha: 0.5);
  static final Color onSurfaceAlpha60 = textDecoration.withValues(alpha: 0.6);

  static final Color shadowAlpha05 = Colors.black.withValues(alpha: 0.05);
  static final Color shadowAlpha10 = Colors.black.withValues(alpha: 0.1);
  static final Color shadowAlpha15 = Colors.black.withValues(alpha: 0.15);

  static final Color onPrimaryAlpha05 = Colors.white.withValues(alpha: 0.05);
  static final Color onPrimaryAlpha10 = Colors.white.withValues(alpha: 0.1);
  static final Color onPrimaryAlpha20 = Colors.white.withValues(alpha: 0.2);
  static final Color onPrimaryAlpha30 = Colors.white.withValues(alpha: 0.3);
  static final Color onPrimaryAlpha80 = Colors.white.withValues(alpha: 0.8);
}
