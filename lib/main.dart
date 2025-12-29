import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/providers/auth_provider.dart';
import 'presentation/pages/login_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/splash_screen.dart';
import 'core/providers/home_provider.dart';
import 'core/providers/product_details_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/history_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/ebara_data_service.dart';
import 'presentation/pages/product_details_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDc79PlVUaRnEYDewdOxr8W1aC-hC16jx8",
      appId: "1:458970213961:web:89e5fc71c5c49e477e5998",
      messagingSenderId: "458970213961",
      projectId: "ebas-egso",
      authDomain: "ebas-egso.firebaseapp.com",
      storageBucket: "ebas-egso.appspot.com",
    ),
  );

  await Hive.initFlutter();
  await _openBoxSafe('api_cache');
  await _openBoxSafe('settings');

  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize(
      clientId:
          '493727106261-70e218fvoquodhjvs1l0g59hpk5ltcu5.apps.googleusercontent.com',
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ProductDetailsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _openBoxSafe(String boxName) async {
  try {
    await Hive.openBox(boxName);
  } catch (e) {
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox(boxName);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final locale = locationProvider.currentLocale;

    final themeMode =
        (authProvider.status == AuthStatus.authenticated &&
            themeProvider.isDarkMode)
        ? ThemeMode.dark
        : ThemeMode.light;

    return MaterialApp(
      title: 'Ebara Brasil',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', ''),
        Locale('en', ''),
        Locale('es', ''),
      ],
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/product/') == true) {
          final uri = Uri.parse(settings.name!);
          if (uri.pathSegments.length >= 3) {
            final categoryId = uri.pathSegments[1];
            final productId = uri.pathSegments[2];
            return MaterialPageRoute(
              builder: (context) => DeepLinkLoadingPage(
                categoryId: categoryId,
                productId: productId,
              ),
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
      },
    );
  }
}

class DeepLinkLoadingPage extends StatefulWidget {
  final String categoryId;
  final String productId;

  const DeepLinkLoadingPage({
    super.key,
    required this.categoryId,
    required this.productId,
  });

  @override
  State<DeepLinkLoadingPage> createState() => _DeepLinkLoadingPageState();
}

class _DeepLinkLoadingPageState extends State<DeepLinkLoadingPage> {
  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    final l10n = AppLocalizations.of(context)!;
    final nav = Navigator.of(context);

    try {
      final results = await EbaraDataService.searchProducts(
        categoryId: widget.categoryId,
        line: 'TODOS',
      );

      final group = EbaraDataService.groupProducts(results);
      final product = group.firstWhere(
        (p) =>
            p.productId == widget.productId ||
            p.variants.any((v) => v.productId == widget.productId),
        orElse: () => throw Exception(l10n.translate('product_not_found')),
      );

      if (mounted) {
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              category: widget.categoryId,
              variants: product.variants.map((e) => e.toMap()).toList(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        nav.pushReplacementNamed('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('product_not_found'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
