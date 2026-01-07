import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';

class AppModalWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? headerAction;
  final double? maxHeightFactor;

  const AppModalWrapper({
    super.key,
    required this.child,
    this.title,
    this.headerAction,
    this.maxHeightFactor = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = context.mediaQuery.viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(
        maxHeight: context.height * (maxHeightFactor ?? 0.9),
      ),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ModalHandle(),
          if (title != null) _ModalHeader(title: title!, action: headerAction),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _ModalHandle extends StatelessWidget {
  const _ModalHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimens.sm),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.colors.onSurface.withValues(alpha: AppDimens.opacityLow),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _ModalHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        0,
        AppDimens.lg,
        AppDimens.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.theme.dividerColor)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title,
            style: context.titleStyle?.copyWith(
              fontSize: AppDimens.fontDisplay,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) Positioned(right: 0, child: action!),
        ],
      ),
    );
  }
}
