import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/constants/app_assets.dart';
import '../../core/router/app_router.dart';
import '../widgets/app_buttons.dart';
import '../theme/app_dimens.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.signInWithGoogle();
      if (!mounted) return;
      context.pushReplacementNamed(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar(
        context.l10n.translate('login_error'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    final auth = context.read<AuthProvider>();
    await auth.continueAsGuest();
    if (!mounted) return;
    context.pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LoginHeader(),
                    const SizedBox(height: AppDimens.iconHuge),
                    AppPrimaryButton(
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      text: context.l10n.translate('enter_google'),
                      isLoading: _isLoading,
                      icon: Icons.login,
                      backgroundColor: colors.onPrimary,
                      foregroundColor: colors.primary,
                    ),
                    const SizedBox(height: AppDimens.md),
                    TextButton(
                      onPressed: _isLoading ? null : _handleGuestLogin,
                      child: Text(
                        context.l10n.translate('continue_guest'),
                        style: context.textTheme.labelLarge?.copyWith(
                          fontSize: AppDimens.fontXl,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.iconHuge),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppDimens.zero,
              right: AppDimens.zero,
              bottom: AppDimens.lg,
              child: Center(
                child: Image.asset(
                  AppAssets.eeps,
                  height: AppDimens.xxxl,
                  cacheHeight:
                      (AppDimens.xxxl * context.mediaQuery.devicePixelRatio)
                          .toInt(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logoSize = AppDimens.xxxl * 2;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimens.lg),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: AppDimens.opacityLow),
                blurRadius: AppDimens.lg,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            AppAssets.logo,
            height: logoSize,
            width: logoSize,
            errorBuilder: (c, o, s) => Icon(
              Icons.water_drop,
              size: AppDimens.iconHuge,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.xxxl),
        Text(
          context.l10n.translate('welcome'),
          style: context.textTheme.displayLarge?.copyWith(
            color: colors.onPrimary,
            fontSize: AppDimens.fontDisplayLg,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        Text(
          context.l10n.translate('login_desc'),
          textAlign: TextAlign.center,
          style: context.bodySmall?.copyWith(
            color: colors.onPrimary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
