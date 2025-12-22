import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shimmer/shimmer.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _startAnimation = true);
    });

    _startAppInitialization();
  }

  void _startAppInitialization() {
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [primaryColor.withAlpha(200), primaryColor],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: _startAnimation ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _startAnimation ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: Shimmer.fromColors(
                  baseColor: Colors.white,
                  highlightColor: Colors.white.withAlpha(120),
                  period: const Duration(seconds: 2),
                  child: Image.asset(
                    'assets/images/logo.png',
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
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black26,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Pump Selector',
                        speed: const Duration(milliseconds: 150),
                        cursor: '',
                      ),
                    ],
                    isRepeatingAnimation: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
