import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../theme/app_colors.dart';
import 'history_modal_sheet.dart';
import 'calculators_bottom_sheet.dart';

class AuthModalSheet extends StatefulWidget {
  const AuthModalSheet({super.key});

  @override
  State<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends State<AuthModalSheet> {
  bool _isLoading = false;

  void _openHistory(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const HistoryModalSheet(),
    );
  }

  void _openCalculators(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    if (auth.status != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('exclusive_feature'))),
      );
      return;
    }

    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CalculatorsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isGuest = authProvider.status == AuthStatus.guest;
    final user = authProvider.user;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isGuest
                ? l10n.translate('want_login')
                : l10n.translate('my_account'),
            style: theme.textTheme.displayMedium?.copyWith(
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
              user.displayName ?? l10n.translate('user'),
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 16),
            ),
            Text(
              user.email ?? "",
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Divider(),
          ] else if (isGuest) ...[
            Text(
              l10n.translate('guest_modal_desc'),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],

          if (!isGuest) ...[
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: Text(
                l10n.translate('history'),
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 16),
              ),
              onTap: () => _openHistory(context),
              contentPadding: EdgeInsets.zero,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            ListTile(
              leading: const Icon(Icons.calculate, color: AppColors.primary),
              title: Text(
                l10n.translate('calculators'),
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 16),
              ),
              onTap: () => _openCalculators(context),
              contentPadding: EdgeInsets.zero,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],

          const SizedBox(height: 25),

          if (isGuest)
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);

                      final auth = context.read<AuthProvider>();
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        await auth.signInWithGoogle();
                        if (mounted) navigator.pop();
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _isLoading = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.translate('connect_error')),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login),
                        const SizedBox(width: 12),
                        Text(l10n.translate('enter_google')),
                      ],
                    ),
            ),

          const SizedBox(height: 10),

          OutlinedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    final auth = context.read<AuthProvider>();
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    await auth.signOut();
                    if (mounted) navigator.pushReplacementNamed('/login');
                  },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: theme.dividerColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isGuest ? l10n.translate('back_login') : l10n.translate('logout'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
