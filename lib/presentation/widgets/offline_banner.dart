import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/localization/app_localizations.dart';

class OfflineBannerWrapper extends StatelessWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityProvider>();
    final isOnline = connectivity.isOnline;
    final l10n = AppLocalizations.of(context);

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        child,
        if (!isOnline)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.redAccent,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.translate('no_internet') ?? 'No connection',
                      style: const TextStyle(
                        color: Colors.white,
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
