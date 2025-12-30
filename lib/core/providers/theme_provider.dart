import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class ThemeProvider with ChangeNotifier {
  final Box _settingsBox = Hive.box(StorageKeys.boxSettings);
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider();

  Future<void> init() async {
    _loadTheme();
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
    _settingsBox.put(StorageKeys.keyIsDarkMode, value);
    notifyListeners();
  }
}
