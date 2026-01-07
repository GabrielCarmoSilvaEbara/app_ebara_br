class AppConstants {
  static const String apiBaseUrl = 'https://ebara.com.br/api';
  static const String ebaraBaseUrl = 'https://ebara.com.br';
  static const String ebaraFilesUrl =
      'https://ebara.com.br/userfiles/aplicacoes';

  static const String apiToken = 'EZTHB1985';
  static const String apiVersion = '1';

  static const String firebaseApiKey =
      "AIzaSyBmig3xgYh8I6JN4FL_GTBmt8wVbG7KaMg";
  static const String firebaseAppId =
      "1:701048514790:web:90d6a9fcb01d5167697327";
  static const String firebaseMessagingSenderId = "701048514790";
  static const String firebaseProjectId = "ebas-site";
  static const String firebaseAuthDomain = "ebas-site.firebaseapp.com";
  static const String firebaseStorageBucket = "ebas-site.appspot.com";

  static const String mapTileUrlLight =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
  static const String mapTileUrlDark =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org';
  static const String userAgent = 'app-ebara/1.0 (contato@seudominio.com)';
}

class CategoryIds {
  static const String submersible = '23';
  static const String solar = '26';
  static const String pressurizer = '27';
  static const String pressurizerSlug = 'sistemas-de-pressurizacao-1';
  static const String industrial = '28';
  static const String residential = '29';
  static const String centrifugal = '22';
}

class StorageKeys {
  static const String boxSettings = 'settings';
  static const String boxApiCache = 'api_cache';

  static const String keyUserLocation = 'user_location';
  static const String keyIsDarkMode = 'is_dark_mode';
  static const String keyIsGuest = 'is_guest';
  static const String keyProductHistory = 'product_history';
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration splash = Duration(milliseconds: 1000);
}
