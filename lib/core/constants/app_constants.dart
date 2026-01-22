import 'package:flutter/material.dart';

class AppConstants {
  static const String apiBaseUrl = 'https://ebara.com.br/api/';
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
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org/';
  static const String userAgent = 'app-ebara/1.0 (contato@seudominio.com)';
}

class CategoryIds {
  static const String centrifugal = '22';
  static const String submersible = '23';
  static const String deepWell = '24';
  static const String solar = '26';
  static const String pressurizer = '27';
  static const String industrial = '28';
  static const String residential = '29';
}

class CategorySlugs {
  static const String centrifugal = 'bombas-centrifugas';
  static const String submerged = 'bombas-submersas';
  static const String submersible = 'bombas-submersiveis';
  static const String solar = 'sistema-solar-ecaros-1';
  static const String pressurizer = 'sistemas-de-pressurizacao-1';
  static const String industrial = 'industrial';
  static const String residential = 'residencial';
}

class CategoryUtil {
  static IconData getIconForCategory(String id, String slug) {
    if (slug == CategorySlugs.centrifugal || id == CategoryIds.centrifugal) {
      return Icons.tune;
    }
    if (slug == CategorySlugs.submerged || id == CategoryIds.deepWell) {
      return Icons.water;
    }
    if (slug == CategorySlugs.submersible || id == CategoryIds.submersible) {
      return Icons.water_drop;
    }
    if (slug == CategorySlugs.solar || id == CategoryIds.solar) {
      return Icons.wb_sunny;
    }
    if (slug == CategorySlugs.pressurizer || id == CategoryIds.pressurizer) {
      return Icons.compress;
    }
    if (slug == CategorySlugs.industrial || id == CategoryIds.industrial) {
      return Icons.factory;
    }
    if (slug == CategorySlugs.residential || id == CategoryIds.residential) {
      return Icons.home;
    }
    return Icons.category;
  }
}

class SystemConstants {
  static const String all = 'TODOS';
  static const String pressostat = 'pressostato';
  static const String inverter = 'inversor';
  static const String defaultValueZero = '0';
  static const String defaultFlowMeasure = 'm3/h';
  static const String defaultHeadMeasure = 'm';
  static const int defaultFrequency = 60;
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
