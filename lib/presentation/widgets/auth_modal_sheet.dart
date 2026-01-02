import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/extensions/context_extensions.dart';
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
    final authProvider = context.read<AuthProvider>();
    final isGuest = authProvider.status == AuthStatus.guest;
    final user = authProvider.user;
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isGuest
                ? context.l10n.translate('want_login')
                : context.l10n.translate('my_account'),
            style: context.textTheme.displayMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (!isGuest && user != null) ...[
            if (user.photoURL != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(user.photoURL!),
                ),
              ),
            Text(
              user.displayName ?? context.l10n.translate('user'),
              style: context.textTheme.displayMedium?.copyWith(fontSize: 16),
            ),
            Text(
              user.email ?? "",
              style: context.textTheme.labelMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
          ] else if (isGuest) ...[
            Text(
              context.l10n.translate('guest_modal_desc'),
              textAlign: TextAlign.center,
              style: context.textTheme.labelMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 0),
          ],
          if (!isGuest) ...[
            ListTile(
              leading: Icon(Icons.history, color: colors.primary),
              title: Text(
                context.l10n.translate('history'),
                style: context.textTheme.displayMedium?.copyWith(fontSize: 16),
              ),
              onTap: () => _openHistory(context),
              contentPadding: EdgeInsets.zero,
              trailing: Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
            ListTile(
              leading: Icon(Icons.calculate, color: colors.primary),
              title: Text(
                context.l10n.translate('calculators'),
                style: context.textTheme.displayMedium?.copyWith(fontSize: 16),
              ),
              onTap: () => _openCalculators(context),
              contentPadding: EdgeInsets.zero,
              trailing: Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
          const SizedBox(height: 10),
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
                        if (mounted) {
                          context.pop();
                        }
                      } catch (e) {
                        if (!mounted) return;
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
          const SizedBox(height: 10),
          AppOutlinedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    final auth = context.read<AuthProvider>();
                    context.pop();
                    await auth.signOut();
                    if (mounted) {
                      context.pushReplacementNamed('/login');
                    }
                  },
            text: isGuest
                ? context.l10n.translate('back_login')
                : context.l10n.translate('logout'),
            textColor: colors.error,
          ),
        ],
      ),
    );
  }
}
