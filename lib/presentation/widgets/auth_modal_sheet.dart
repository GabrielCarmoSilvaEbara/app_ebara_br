import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';
import 'app_modal_wrapper.dart';
import 'history_modal_sheet.dart';
import 'calculators_bottom_sheet.dart';
import 'app_buttons.dart';

class AuthModalSheet extends StatefulWidget {
  const AuthModalSheet({super.key});

  @override
  State<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends State<AuthModalSheet> {
  bool _isLoading = false;

  void _openHistory(BuildContext context) {
    context.pop();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface.withValues(alpha: 0),
      isScrollControlled: true,
      builder: (context) => const HistoryModalSheet(),
    );
  }

  void _openCalculators(BuildContext context) {
    final auth = context.read<AuthProvider>();

    if (auth.status != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.translate('exclusive_feature'))),
      );
      return;
    }

    context.pop();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface.withValues(alpha: 0),
      isScrollControlled: true,
      builder: (context) => const CalculatorsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppModalWrapper(
      maxHeightFactor: AppDimens.modalHeightSm,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
        child: Selector<AuthProvider, (AuthStatus, String?, String?, String?)>(
          selector: (_, p) =>
              (p.status, p.user?.displayName, p.user?.email, p.user?.photoURL),
          builder: (context, data, _) {
            final status = data.$1;
            final isGuest = status == AuthStatus.guest;
            final isAuthenticated = status == AuthStatus.authenticated;
            final name = data.$2;
            final email = data.$3;
            final photo = data.$4;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isGuest
                      ? context.l10n.translate('want_login')
                      : context.l10n.translate('my_account'),
                  style: context.textTheme.displayMedium?.copyWith(
                    fontSize: AppDimens.fontDisplay,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                if (isAuthenticated) ...[
                  if (photo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.sm),
                      child: CircleAvatar(
                        radius: AppDimens.radiusXxl,
                        backgroundImage: NetworkImage(photo),
                      ),
                    ),
                  Text(
                    name ?? context.l10n.translate('user'),
                    style: context.textTheme.displayMedium?.copyWith(
                      fontSize: AppDimens.fontXl,
                    ),
                  ),
                  Text(
                    email ?? "",
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.onSurface.withValues(
                        alpha: AppDimens.opacityHigh,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  const Divider(),
                ] else if (isGuest) ...[
                  Text(
                    context.l10n.translate('guest_modal_desc'),
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.onSurface.withValues(
                        alpha: AppDimens.opacityHigh,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.zero),
                ],
                if (!isGuest) ...[
                  ListTile(
                    leading: Icon(Icons.history, color: colors.primary),
                    title: Text(
                      context.l10n.translate('history'),
                      style: context.textTheme.displayMedium?.copyWith(
                        fontSize: AppDimens.fontXl,
                      ),
                    ),
                    onTap: () => _openHistory(context),
                    contentPadding: EdgeInsets.zero,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colors.onSurface.withValues(
                        alpha: AppDimens.opacityHigh,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.calculate, color: colors.primary),
                    title: Text(
                      context.l10n.translate('calculators'),
                      style: context.textTheme.displayMedium?.copyWith(
                        fontSize: AppDimens.fontXl,
                      ),
                    ),
                    onTap: () => _openCalculators(context),
                    contentPadding: EdgeInsets.zero,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colors.onSurface.withValues(
                        alpha: AppDimens.opacityHigh,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppDimens.gridSpacing),
                if (isGuest)
                  AppPrimaryButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            final auth = context.read<AuthProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await auth.signInWithGoogle();
                              if (context.mounted) {
                                context.pop();
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() => _isLoading = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.translate('connect_error'),
                                  ),
                                ),
                              );
                            }
                          },
                    text: context.l10n.translate('enter_google'),
                    isLoading: _isLoading,
                    icon: Icons.login,
                    foregroundColor: colors.onPrimary,
                  ),
                const SizedBox(height: AppDimens.gridSpacing),
                AppOutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final auth = context.read<AuthProvider>();
                          context.pop();
                          await auth.signOut();
                          if (context.mounted) {
                            context.pushReplacementNamed('/login');
                          }
                        },
                  text: isGuest
                      ? context.l10n.translate('back_login')
                      : context.l10n.translate('logout'),
                  textColor: colors.error,
                ),
                const SizedBox(height: AppDimens.lg),
              ],
            );
          },
        ),
      ),
    );
  }
}
