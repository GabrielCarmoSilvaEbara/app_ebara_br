import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logViewProduct(
    String id,
    String name,
    String category,
  ) async {
    await _analytics.logViewItem(
      currency: 'BRL',
      items: [
        AnalyticsEventItem(itemId: id, itemName: name, itemCategory: category),
      ],
    );
  }

  static Future<void> logSearchFilters({
    required double flowRate,
    required double head,
    required String application,
    required String categoryId,
  }) async {
    await _analytics.logEvent(
      name: 'pump_search',
      parameters: {
        'flow_rate': flowRate,
        'head_gauge': head,
        'application': application,
        'category_id': categoryId,
      },
    );
  }

  static Future<void> setUserLocation(String city, String state) async {
    await _analytics.setUserProperty(name: 'user_city', value: city);
    await _analytics.setUserProperty(name: 'user_state', value: state);
    await _analytics.logEvent(
      name: 'change_location',
      parameters: {'city': city, 'state': state},
    );
  }

  static Future<void> logCompareProducts(
    String baseId,
    String compareId,
  ) async {
    await _analytics.logEvent(
      name: 'compare_products',
      parameters: {'base_product_id': baseId, 'compare_product_id': compareId},
    );
  }

  static Future<void> logDownloadDocument(
    String fileName,
    String productName,
  ) async {
    await _analytics.logEvent(
      name: 'download_document',
      parameters: {'file_name': fileName, 'product_name': productName},
    );
  }
}
