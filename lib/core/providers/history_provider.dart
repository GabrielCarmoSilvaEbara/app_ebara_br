import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/history_item_model.dart';
import '../constants/app_constants.dart';

class HistoryProvider with ChangeNotifier {
  final Box _settingsBox = Hive.box(StorageKeys.boxSettings);
  List<HistoryItemModel> _history = [];

  List<HistoryItemModel> get history => _history;

  HistoryProvider();

  Future<void> init() async {
    _loadHistory();
  }

  void _loadHistory() {
    try {
      final List<dynamic>? data = _settingsBox.get(
        StorageKeys.keyProductHistory,
      );
      if (data != null) {
        _history = data.map((e) => HistoryItemModel.fromJson(e)).toList();
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
    final newItem = HistoryItemModel(
      id: product['id']?.toString() ?? '',
      name: product['name'] ?? '',
      model: product['model'] ?? '',
      image: product['image'] ?? '',
      category: category,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      variants: product['variants'] ?? [],
    );

    _history.removeWhere((e) => e.id == newItem.id);
    _history.insert(0, newItem);

    if (_history.length > 20) {
      _history = _history.sublist(0, 20);
    }

    notifyListeners();
    await _saveHistory();
  }

  Future<void> removeFromHistory(String id) async {
    _history.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    await _settingsBox.delete(StorageKeys.keyProductHistory);
  }

  Future<void> _saveHistory() async {
    final List<String> encoded = _history.map((e) => e.toJson()).toList();
    await _settingsBox.put(StorageKeys.keyProductHistory, encoded);
  }
}
