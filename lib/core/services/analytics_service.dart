import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsEvents {
  static const String login = 'login';
  static const String viewItem = 'view_item';
  static const String pumpSearch = 'pump_search';
  static const String changeLocation = 'change_location';
  static const String compareProducts = 'compare_products';
  static const String downloadDocument = 'download_document';
}

class AnalyticsParams {
  static const String method = 'login_method';
  static const String flowRate = 'flow_rate';
  static const String headGauge = 'head_gauge';
  static const String application = 'application';
  static const String categoryId = 'category_id';
  static const String city = 'city';
  static const String state = 'state';
  static const String userCity = 'user_city';
  static const String userState = 'user_state';
  static const String baseProductId = 'base_product_id';
  static const String compareProductId = 'compare_product_id';
  static const String fileName = 'file_name';
  static const String productName = 'product_name';
  static const String currency = 'BRL';
}

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
      currency: AnalyticsParams.currency,
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
      name: AnalyticsEvents.pumpSearch,
      parameters: {
        AnalyticsParams.flowRate: flowRate,
        AnalyticsParams.headGauge: head,
        AnalyticsParams.application: application,
        AnalyticsParams.categoryId: categoryId,
      },
    );
  }

  static Future<void> setUserLocation(String city, String state) async {
    await _analytics.setUserProperty(
      name: AnalyticsParams.userCity,
      value: city,
    );
    await _analytics.setUserProperty(
      name: AnalyticsParams.userState,
      value: state,
    );
    await _analytics.logEvent(
      name: AnalyticsEvents.changeLocation,
      parameters: {AnalyticsParams.city: city, AnalyticsParams.state: state},
    );
  }

  static Future<void> logCompareProducts(
    String baseId,
    String compareId,
  ) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.compareProducts,
      parameters: {
        AnalyticsParams.baseProductId: baseId,
        AnalyticsParams.compareProductId: compareId,
      },
    );
  }

  static Future<void> logDownloadDocument(
    String fileName,
    String productName,
  ) async {
    await _analytics.logEvent(
      name: AnalyticsEvents.downloadDocument,
      parameters: {
        AnalyticsParams.fileName: fileName,
        AnalyticsParams.productName: productName,
      },
    );
  }
}
