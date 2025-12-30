import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryProvider with ChangeNotifier {
  final Box _settingsBox = Hive.box('settings');
  List<Map<String, dynamic>> _history = [];

  List<Map<String, dynamic>> get history => _history;

  HistoryProvider();

  Future<void> init() async {
    _loadHistory();
  }

  void _loadHistory() {
    try {
      final List<dynamic>? data = _settingsBox.get('product_history');
      if (data != null) {
        _history = data
            .map((e) => Map<String, dynamic>.from(jsonDecode(e)))
            .toList();
      }
    } catch (_) {
      _history = [];
    }
    notifyListeners();
  }

  Future<void> addToHistory(
    Map<String, dynamic> product,
    String category,
  ) async {
    final Map<String, dynamic> item = {
      ...product,
      'history_category': category,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _history.removeWhere((e) => e['id'] == item['id']);

    _history.insert(0, item);

    if (_history.length > 20) {
      _history = _history.sublist(0, 20);
    }

    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    await _settingsBox.delete('product_history');
  }

  Future<void> _saveHistory() async {
    final List<String> encoded = _history.map((e) => jsonEncode(e)).toList();
    await _settingsBox.put('product_history', encoded);
  }
}
