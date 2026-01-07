import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/providers/splash_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/constants/app_assets.dart';
import '../theme/app_dimens.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'location_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }

  void _initServices() {
    context.read<SplashProvider>().initApp(
      authProvider: context.read<AuthProvider>(),
      historyProvider: context.read<HistoryProvider>(),
      themeProvider: context.read<ThemeProvider>(),
      connectivityProvider: context.read<ConnectivityProvider>(),
      locationProvider: context.read<LocationProvider>(),
      homeProvider: context.read<HomeProvider>(),
    );
  }

  void _checkNavigation() {
    if (!_animationCompleted) return;

    final splashProvider = context.read<SplashProvider>();
    if (!splashProvider.isInitialized) return;

    final locationProvider = context.read<LocationProvider>();
    final authProvider = context.read<AuthProvider>();
    final String chooseLocationText = context.l10n.translate('choose_location');

    if (locationProvider.city == chooseLocationText ||
        locationProvider.city.isEmpty) {
      _navigate(const LocationPage(isInitialSelection: true));
    } else {
      final isAuth =
          authProvider.status == AuthStatus.authenticated ||
          authProvider.status == AuthStatus.guest;
      _navigate(isAuth ? const HomePage() : const LoginPage());
    }
  }

  void _navigate(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => page,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: AppDimens.durationPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    context.watch<SplashProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNavigation());

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [colors.primary.withValues(alpha: 0.78), colors.primary],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1.0),
                    duration: AppDimens.durationShimmer,
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Shimmer.fromColors(
                      baseColor: colors.onPrimary,
                      highlightColor: colors.onPrimary.withValues(alpha: 0.47),
                      period: const Duration(seconds: 2),
                      child: Image.asset(
                        AppAssets.logo,
                        height: AppDimens.splashLogoSize,
                        width: AppDimens.splashLogoWidth,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.radiusXxl),
                  SizedBox(
                    height: AppDimens.xxxl,
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: AppDimens.fontSplash,
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimary,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            blurRadius: AppDimens.gridSpacing,
                            color: colors.shadow.withValues(alpha: 0.26),
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            context.l10n.translate('pump_selector'),
                            speed: const Duration(milliseconds: 150),
                            cursor: '',
                          ),
                        ],
                        isRepeatingAnimation: false,
                        onFinished: () {
                          if (mounted) {
                            setState(() => _animationCompleted = true);
                            _checkNavigation();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppDimens.xxxl,
              child: Center(
                child: Image.asset(AppAssets.eeps, height: AppDimens.xxxl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
