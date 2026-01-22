import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../services/ebara_data_service.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/cache_service.dart';
import '../services/download_service.dart';
import '../services/notification_service.dart';
import '../repositories/product_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/products_provider.dart';
import '../providers/product_details_provider.dart';
import '../providers/location_provider.dart';
import '../providers/history_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/splash_provider.dart';
import '../providers/home_provider.dart';
import '../constants/app_constants.dart';

class ProviderSetup {
  static Future<List<SingleChildWidget>> getProviders() async {
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
        create: (ctx) => ProductDetailsProvider(
          dataService: ebaraDataService,
          downloadService: downloadService,
        ),
      ),
      ChangeNotifierProvider(
        create: (ctx) => LocationProvider(locationService: locationService),
      ),
      ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SplashProvider()),
    ];
  }
}
