import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/home_provider.dart';
import 'core/providers/product_details_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/history_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/ebara_data_service.dart';
import 'core/services/location_service.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'presentation/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 300;

  await Hive.initFlutter();
  await _openBoxSafe(StorageKeys.boxSettings);
  await _openBoxSafe(StorageKeys.boxApiCache);

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

  final ebaraDataService = EbaraDataService();
  final locationService = LocationService();

  runApp(
    MultiProvider(
      providers: [
        Provider<EbaraDataService>.value(value: ebaraDataService),
        Provider<LocationService>.value(value: locationService),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (ctx) =>
              HomeProvider(dataService: ctx.read<EbaraDataService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              ProductDetailsProvider(dataService: ctx.read<EbaraDataService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              LocationProvider(locationService: ctx.read<LocationService>()),
        ),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
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
    final themeProvider = context.watch<ThemeProvider>();
    final locale = locationProvider.currentLocale;

    final themeMode = themeProvider.isDarkMode
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
      builder: (context, child) {
        return OfflineBannerWrapper(child: child!);
      },
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
