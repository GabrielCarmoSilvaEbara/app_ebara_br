import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final contentColor = isSelected ? colors.onPrimary : colors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md,
              vertical: AppDimens.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
              border: Border.all(
                color: isSelected
                    ? colors.primary
                    : colors.primary.withValues(alpha: AppDimens.opacityMed),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppDimens.iconLg, color: contentColor),
                const SizedBox(width: AppDimens.xs),
                Text(
                  label,
                  style: TextStyle(
                    color: contentColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: AppDimens.fontLg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
