import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart' as anim;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'presentation/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/categories_provider.dart';
import 'core/providers/products_provider.dart';
import 'core/providers/product_details_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/history_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/splash_provider.dart';
import 'core/providers/home_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/ebara_data_service.dart';
import 'core/services/api_service.dart';
import 'core/services/location_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/download_service.dart';
import 'core/services/notification_service.dart';
import 'core/repositories/product_repository.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'presentation/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: AppConstants.firebaseApiKey,
        appId: AppConstants.firebaseAppId,
        messagingSenderId: AppConstants.firebaseMessagingSenderId,
        projectId: AppConstants.firebaseProjectId,
        authDomain: AppConstants.firebaseAuthDomain,
        storageBucket: AppConstants.firebaseStorageBucket,
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<List<dynamic>> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initServices();
  }

  Future<List<dynamic>> _initServices() async {
    PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 300;

    await Hive.initFlutter();
    await _initHiveBox(StorageKeys.boxSettings, isCritical: true);

    final cacheService = await CacheService.init();

    final apiService = ApiService(
      baseUrl: AppConstants.apiBaseUrl,
      cacheService: cacheService,
      defaultHeaders: {
        'Content-Type': 'application/json',
        'api-version': AppConstants.apiVersion,
        'api-token': AppConstants.apiToken,
      },
    );

    final connectivityProvider = ConnectivityProvider();
    await connectivityProvider.init();

    final ebaraDataService = EbaraDataService(api: apiService);
    final locationService = LocationService();
    final downloadService = DownloadService();

    final notificationService = NotificationService();
    await notificationService.init();

    final productRepository = ProductRepository(
      api: apiService,
      cache: cacheService,
      connectivity: connectivityProvider,
    );

    return [
      ebaraDataService,
      locationService,
      productRepository,
      connectivityProvider,
      downloadService,
      notificationService,
    ];
  }

  Future<void> _initHiveBox(String boxName, {bool isCritical = false}) async {
    try {
      await Hive.openBox(boxName);
    } catch (e) {
      if (!isCritical) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          await Hive.openBox(boxName);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            !snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(backgroundColor: Color(0xFF004F9F)),
          );
        }

        final services = snapshot.data!;
        final ebaraDataService = services[0] as EbaraDataService;
        final locationService = services[1] as LocationService;
        final productRepository = services[2] as ProductRepository;
        final connectivityProvider = services[3] as ConnectivityProvider;
        final downloadService = services[4] as DownloadService;
        final notificationService = services[5] as NotificationService;

        return MultiProvider(
          providers: [
            Provider<EbaraDataService>.value(value: ebaraDataService),
            Provider<LocationService>.value(value: locationService),
            Provider<ProductRepository>.value(value: productRepository),
            Provider<DownloadService>.value(value: downloadService),
            Provider<NotificationService>.value(value: notificationService),
            ChangeNotifierProvider.value(value: connectivityProvider),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(
              create: (_) => CategoriesProvider(repository: productRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => ProductsProvider(
                repository: productRepository,
                dataService: ebaraDataService,
              ),
            ),
            ChangeNotifierProvider(
              create: (ctx) => HomeProvider(
                productsProvider: ctx.read<ProductsProvider>(),
                categoriesProvider: ctx.read<CategoriesProvider>(),
                dataService: ebaraDataService,
              ),
            ),
            ChangeNotifierProvider(
              create: (ctx) =>
                  ProductDetailsProvider(dataService: ebaraDataService),
            ),
            ChangeNotifierProvider(
              create: (ctx) =>
                  LocationProvider(locationService: locationService),
            ),
            ChangeNotifierProvider(create: (_) => HistoryProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => SplashProvider()),
          ],
          child: const MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.select<LocationProvider, Locale>(
      (p) => p.currentLocale,
    );
    final themeProvider = context.watch<ThemeProvider>();

    return anim.ThemeProvider(
      initTheme: themeProvider.isDarkMode
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      builder: (context, theme) {
        return MaterialApp.router(
          title: 'Ebara Brasil',
          theme: theme,
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
          routerConfig: AppRouter.router,
          builder: (context, child) {
            Intl.defaultLocale = locale.toString();
            return OfflineBannerWrapper(child: child!);
          },
        );
      },
    );
  }
}
