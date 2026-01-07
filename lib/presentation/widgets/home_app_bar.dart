import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart' as app_theme;
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';
import '../pages/location_page.dart';
import 'auth_modal_sheet.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        AppDimens.appBarTopPadding,
        AppDimens.lg,
        AppDimens.zero,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: AppDimens.zero,
              child: ThemeSwitcher(
                builder: (context) {
                  return GestureDetector(
                    onTap: () {
                      final themeProv = context.read<app_theme.ThemeProvider>();
                      final isDark = themeProv.isDarkMode;
                      final nextTheme = themeProv.getThemeData(!isDark);
                      themeProv.toggleTheme(!isDark);
                      ThemeSwitcher.of(
                        context,
                      ).changeTheme(theme: nextTheme, isReversed: isDark);
                    },
                    child: Container(
                      width: AppDimens.xxxl,
                      height: AppDimens.xxxl,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(
                              alpha: AppDimens.opacityBackground,
                            ),
                            blurRadius: AppDimens.gridSpacing,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        ThemeModelInheritedNotifier.of(
                                  context,
                                ).theme.brightness ==
                                Brightness.dark
                            ? Icons.nightlight_round
                            : Icons.wb_sunny,
                        color: colors.primary,
                        size: AppDimens.iconTheme,
                      ),
                    ),
                  );
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationPage()),
                );
              },
              child: Selector<LocationProvider, String>(
                selector: (_, provider) => provider.city,
                builder: (context, city, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: AppDimens.iconXs,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.translate('location'),
                            style: context.bodySmall,
                          ),
                        ],
                      ),
                      Text(
                        city.isEmpty
                            ? context.l10n.translate('choose_location')
                            : city,
                        style: context.titleStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              right: AppDimens.zero,
              child: GestureDetector(
                onTap: () {
                  context.showAppBottomSheet(child: const AuthModalSheet());
                },
                child: Container(
                  width: AppDimens.xxxl,
                  height: AppDimens.xxxl,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(
                      alpha: AppDimens.opacityLow,
                    ),
                  ),
                  child: Selector<AuthProvider, String?>(
                    selector: (_, provider) => provider.user?.photoURL,
                    builder: (context, photoUrl, _) {
                      if (photoUrl != null) {
                        return ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) =>
                                Icon(Icons.person, color: colors.primary),
                          ),
                        );
                      }
                      return Icon(
                        Icons.person,
                        color:
                            context.read<AuthProvider>().status ==
                                AuthStatus.authenticated
                            ? colors.primary
                            : colors.onSurface.withValues(
                                alpha: AppDimens.opacityHigh,
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
