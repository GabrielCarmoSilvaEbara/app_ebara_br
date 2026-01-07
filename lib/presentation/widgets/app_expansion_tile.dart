import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';

class AppExpansionTile extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final ExpansibleController? controller;
  final ValueChanged<bool>? onExpansionChanged;

  const AppExpansionTile({
    super.key,
    required this.title,
    required this.children,
    this.controller,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final textColor = isDark
        ? context.colors.onPrimary
        : context.colors.primary;

    return Theme(
      data: context.theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        controller: controller,
        onExpansionChanged: onExpansionChanged,
        tilePadding: EdgeInsets.zero,
        title: Text(
          title,
          style: context.subtitleStyle?.copyWith(
            color: textColor,
            fontSize: AppDimens.fontSm,
          ),
        ),
        iconColor: textColor,
        collapsedIconColor: textColor,
        children: children,
      ),
    );
  }
}
