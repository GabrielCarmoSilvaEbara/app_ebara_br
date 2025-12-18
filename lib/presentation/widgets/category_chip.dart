import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Ink(
            decoration: _buildDecoration(context),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: _getContentColor(context)),
                const SizedBox(width: 8),
                Text(label, style: _getTextStyle(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BoxDecoration(
      color: isSelected ? colorScheme.primary : colorScheme.secondary,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.primary.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }

  Color _getContentColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return isSelected ? colorScheme.onPrimary : colorScheme.primary;
  }

  TextStyle _getTextStyle(BuildContext context) {
    return TextStyle(
      color: _getContentColor(context),
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      fontSize: 14,
    );
  }
}
