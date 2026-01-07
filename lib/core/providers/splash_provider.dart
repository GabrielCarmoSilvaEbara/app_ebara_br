import 'dart:async';
import 'package:flutter/material.dart';
import 'home_provider.dart';
import 'location_provider.dart';
import 'auth_provider.dart';
import 'history_provider.dart';
import 'theme_provider.dart';
import 'connectivity_provider.dart';

class SplashProvider with ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initApp({
    required AuthProvider authProvider,
    required HistoryProvider historyProvider,
    required ThemeProvider themeProvider,
    required ConnectivityProvider connectivityProvider,
    required LocationProvider locationProvider,
    required HomeProvider homeProvider,
  }) async {
    if (_isInitialized) return;

    try {
      await Future.wait([
        authProvider.init(),
        historyProvider.init(),
        themeProvider.init(),
        connectivityProvider.init(),
        locationProvider.initLocation(),
      ]);

      unawaited(homeProvider.reloadData(locationProvider.apiLanguageId));
    } catch (e) {
      debugPrint("Initialization error: $e");
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }
}
