import 'package:flutter/material.dart';
import 'app_dimens.dart';

class AppStyles {
  static BoxDecoration cardDecoration(
    BuildContext context, {
    Color? color,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: color ?? theme.cardColor,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      border: borderColor != null ? Border.all(color: borderColor) : null,
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withValues(alpha: 0.05),
          blurRadius: AppDimens.xxs,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
