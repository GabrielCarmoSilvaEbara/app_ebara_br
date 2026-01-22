import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart' as anim;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'presentation/theme/app_theme.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/di/provider_setup.dart';
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

  await Hive.initFlutter();
  await _initHiveBox(StorageKeys.boxSettings, isCritical: true);

  runApp(const AppBootstrap());
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
    PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 300;
    _initFuture = ProviderSetup.getProviders();
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

        return MultiProvider(
          providers: snapshot.data! as List<SingleChildWidget>,
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
