import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/splash_screen.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/location_page.dart';
import '../../presentation/pages/product_details_page.dart';
import '../../presentation/pages/deep_link_loading_page.dart';
import '../../presentation/pages/pdf_viewer_page.dart';
import '../../presentation/widgets/image_viewer.dart';
import '../../core/models/product_model.dart';

class AppRoutes {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String home = 'home';
  static const String location = 'location';
  static const String productDetails = 'product_details';
  static const String deepLinkProduct = 'deep_link_product';
  static const String imageViewer = 'image_viewer';
  static const String pdfViewer = 'pdf_viewer';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/location',
        name: AppRoutes.location,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isInitial = extra?['isInitialSelection'] as bool? ?? false;
          return LocationPage(isInitialSelection: isInitial);
        },
      ),
      GoRoute(
        path: '/product-details',
        name: AppRoutes.productDetails,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ProductDetailsPage(
            category: extra['category'] as String,
            variants: extra['variants'] as List<ProductModel>,
          );
        },
      ),
      GoRoute(
        path: '/product/:categoryId/:productId',
        name: AppRoutes.deepLinkProduct,
        builder: (context, state) {
          return DeepLinkLoadingPage(
            categoryId: state.pathParameters['categoryId']!,
            productId: state.pathParameters['productId']!,
          );
        },
      ),
      GoRoute(
        path: '/image-viewer',
        name: AppRoutes.imageViewer,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            fullscreenDialog: true,
            opaque: false,
            child: ImageViewer(
              imageUrl: extra['imageUrl'] as String,
              heroTag: extra['heroTag'] as String,
            ),
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/pdf-viewer',
        name: AppRoutes.pdfViewer,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PdfViewerPage(
            path: extra['path'] as String,
            title: extra['title'] as String,
          );
        },
      ),
    ],
  );
}
