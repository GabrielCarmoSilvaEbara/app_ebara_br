class AppConstants {
  static const String apiBaseUrl = 'https://ebara.com.br/api';
  static const String apiToken = 'EZTHB1985';
  static const String apiVersion = '1';

  static const String firebaseApiKey =
      "AIzaSyDc79PlVUaRnEYDewdOxr8W1aC-hC16jx8";
  static const String firebaseAppId =
      "1:458970213961:web:89e5fc71c5c49e477e5998";
  static const String firebaseMessagingSenderId = "458970213961";
  static const String firebaseProjectId = "ebas-egso";
  static const String firebaseAuthDomain = "ebas-egso.firebaseapp.com";
  static const String firebaseStorageBucket = "ebas-egso.appspot.com";

  static const String mapTileUrlLight =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
  static const String mapTileUrlDark =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org';
  static const String userAgent = 'app-ebara/1.0 (contato@seudominio.com)';
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
