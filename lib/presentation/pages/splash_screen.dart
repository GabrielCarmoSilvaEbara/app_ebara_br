import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_assets.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'location_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _startAnimation = false;

  final Completer<void> _apiDataCompleter = Completer<void>();
  final Completer<void> _textAnimationCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResources();
    });

    Future.delayed(AppDurations.normal, () {
      if (mounted) {
        setState(() => _startAnimation = true);
      }
    });

    _handleTransition();
  }

  void _loadResources() async {
    try {
      final locProv = context.read<LocationProvider>();
      final homeProv = context.read<HomeProvider>();
      final authProv = context.read<AuthProvider>();
      final historyProv = context.read<HistoryProvider>();
      final themeProv = context.read<ThemeProvider>();
      final connProv = context.read<ConnectivityProvider>();

      await Future.wait([
        authProv.init(),
        historyProv.init(),
        themeProv.init(),
        connProv.init(),
        locProv.initLocation(),
        _initHeavyServices(),
      ]);

      if (mounted) {
        await homeProv.reloadData(locProv.apiLanguageId);
      }
    } catch (_) {
    } finally {
      if (!_apiDataCompleter.isCompleted) {
        _apiDataCompleter.complete();
      }
    }
  }

  Future<void> _initHeavyServices() async {
    try {
      await Hive.openBox(StorageKeys.boxApiCache);
    } catch (e) {
      await Hive.deleteBoxFromDisk(StorageKeys.boxApiCache);
      await Hive.openBox(StorageKeys.boxApiCache);
    }
  }

  Future<void> _handleTransition() async {
    try {
      await Future.wait([
        _apiDataCompleter.future,
        _textAnimationCompleter.future,
      ]).timeout(const Duration(seconds: 5));
    } catch (e) {
      //
    } finally {
      if (mounted) {
        _decideNextPage();
      }
    }
  }

  void _decideNextPage() {
    final locationProvider = context.read<LocationProvider>();
    final authProvider = context.read<AuthProvider>();

    final String chooseLocationText = context.l10n.translate('choose_location');

    if (locationProvider.city == chooseLocationText ||
        locationProvider.city.isEmpty) {
      _navigateToPage(const LocationPage(isInitialSelection: true));
    } else {
      if (authProvider.status == AuthStatus.authenticated ||
          authProvider.status == AuthStatus.guest) {
        _navigateToPage(const HomePage());
      } else {
        _navigateToPage(const LoginPage());
      }
    }
  }

  void _navigateToPage(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    if (!_apiDataCompleter.isCompleted) {
      _apiDataCompleter.complete();
    }
    if (!_textAnimationCompleter.isCompleted) {
      _textAnimationCompleter.complete();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                  AnimatedScale(
                    scale: _startAnimation ? 1.0 : 0.7,
                    duration: AppDurations.splash,
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: _startAnimation ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 800),
                      child: Shimmer.fromColors(
                        baseColor: colors.onPrimary,
                        highlightColor: colors.onPrimary.withValues(
                          alpha: 0.47,
                        ),
                        period: const Duration(seconds: 2),
                        child: Image.asset(
                          AppAssets.logo,
                          height: 140,
                          width: 131,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_startAnimation)
                    SizedBox(
                      height: 40,
                      child: DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colors.onPrimary,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
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
                            if (!_textAnimationCompleter.isCompleted) {
                              _textAnimationCompleter.complete();
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
              bottom: 40,
              child: Center(child: Image.asset(AppAssets.eeps, height: 40)),
            ),
          ],
        ),
      ),
    );
  }
}
