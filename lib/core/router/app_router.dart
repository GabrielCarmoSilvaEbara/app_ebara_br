import 'package:flutter/material.dart';
import '../../presentation/pages/splash_screen.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/deep_link_loading_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (settings.name?.startsWith('/product/') == true) {
      final uri = Uri.parse(settings.name!);
      if (uri.pathSegments.length >= 3) {
        final categoryId = uri.pathSegments[1];
        final productId = uri.pathSegments[2];
        return MaterialPageRoute(
          builder: (context) =>
              DeepLinkLoadingPage(categoryId: categoryId, productId: productId),
        );
      }
    }

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
