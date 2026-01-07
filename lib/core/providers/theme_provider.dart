import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  late Box _settingsBox;
  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    if (Hive.isBoxOpen(StorageKeys.boxSettings)) {
      _settingsBox = Hive.box(StorageKeys.boxSettings);
      _isDarkMode = _settingsBox.get(
        StorageKeys.keyIsDarkMode,
        defaultValue: false,
      );
      _isInitialized = true;
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (!Hive.isBoxOpen(StorageKeys.boxSettings)) {
        _settingsBox = await Hive.openBox(StorageKeys.boxSettings);
      } else {
        _settingsBox = Hive.box(StorageKeys.boxSettings);
      }
      _loadTheme();
      _isInitialized = true;
    } catch (_) {
      _isDarkMode = false;
    }
  }

  void _loadTheme() {
    _isDarkMode = _settingsBox.get(
      StorageKeys.keyIsDarkMode,
      defaultValue: false,
    );
    notifyListeners();
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    if (_isInitialized) {
      _settingsBox.put(StorageKeys.keyIsDarkMode, value);
    }
    notifyListeners();
  }

  ThemeData getThemeData(bool isDark) {
    return isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
  }
}
