import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
// import '../../core/providers/theme_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../theme/app_colors.dart';

class AuthModalSheet extends StatefulWidget {
  const AuthModalSheet({super.key});

  @override
  State<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends State<AuthModalSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    // final themeProvider = context.watch<ThemeProvider>();
    final isGuest = authProvider.status == AuthStatus.guest;
    final user = authProvider.user;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isGuest
                ? l10n.translate('want_login')
                : l10n.translate('my_account'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          if (isGuest)
            Text(
              l10n.translate('guest_modal_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            )
          else
            Column(
              children: [
                if (user?.photoURL != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(user!.photoURL!),
                    ),
                  ),
                Text(
                  user?.displayName ?? l10n.translate('user'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Text(
                  user?.email ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
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
                        if (mounted) {
                          setState(() => _isLoading = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.translate('connect_error')),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.6,
                ),
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
              side: BorderSide(color: Colors.grey.shade300),
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
