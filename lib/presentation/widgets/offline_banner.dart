import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';

class OfflineBannerWrapper extends StatelessWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = context.mediaQuery.padding.bottom;

    return Stack(
      children: [
        child,
        Selector<ConnectivityProvider, bool>(
          selector: (_, p) => p.isOnline,
          builder: (context, isOnline, _) {
            if (isOnline) return const SizedBox.shrink();

            final colors = context.colors;
            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                color: colors.error,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.md,
                    AppDimens.xs,
                    AppDimens.md,
                    AppDimens.xs + bottomPadding,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        color: colors.onError,
                        size: AppDimens.iconSm,
                      ),
                      const SizedBox(width: AppDimens.xs),
                      Text(
                        context.l10n.translate('no_internet'),
                        style: TextStyle(
                          color: colors.onError,
                          fontSize: AppDimens.fontSm,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
