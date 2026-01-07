import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import 'app_buttons.dart';
import '../theme/app_dimens.dart';

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppDimens.iconHuge,
            color: colors.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimens.md),
          Text(message, style: context.bodyStyle, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppDimens.md),
            AppPrimaryButton(
              onPressed: onRetry,
              text: context.l10n.translate('try_again'),
              width: AppDimens.buttonWidthSm,
              height: 45,
            ),
          ],
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.search_off,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppDimens.iconHuge,
            color: colors.onSurface.withValues(alpha: AppDimens.opacityMed),
          ),
          const SizedBox(height: AppDimens.md),
          Text(message, style: context.bodyStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
