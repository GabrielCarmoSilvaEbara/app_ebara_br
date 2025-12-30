import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider with ChangeNotifier {
  final Box _settingsBox = Hive.box('settings');
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider();

  Future<void> init() async {
    _loadTheme();
  }

  void _loadTheme() {
    _isDarkMode = _settingsBox.get('is_dark_mode', defaultValue: false);
    notifyListeners();
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    _settingsBox.put('is_dark_mode', value);
    notifyListeners();
  }
}
