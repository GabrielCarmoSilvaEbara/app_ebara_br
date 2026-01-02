import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/extensions/context_extensions.dart';

class OfflineBannerWrapper extends StatelessWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityProvider>();
    final isOnline = connectivity.isOnline;
    final bottomPadding = context.mediaQuery.padding.bottom;
    final colors = context.colors;

    return Stack(
      children: [
        child,
        if (!isOnline)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: colors.error,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: colors.onError, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.translate('no_internet'),
                      style: TextStyle(
                        color: colors.onError,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
