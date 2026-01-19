import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class CacheService {
  final Box _box;

  CacheService._(this._box);

  static Future<CacheService> init() async {
    try {
      final box = await Hive.openBox(StorageKeys.boxApiCache);
      return CacheService._(box);
    } catch (e) {
      try {
        await Hive.deleteBoxFromDisk(StorageKeys.boxApiCache);
      } catch (_) {}
      final box = await Hive.openBox(StorageKeys.boxApiCache);
      return CacheService._(box);
    }
  }

  T? get<T>(
    String key, {
    Duration? validDuration,
    bool deleteIfExpired = true,
  }) {
    if (!_box.containsKey(key)) return null;

    try {
      final entry = Map<String, dynamic>.from(_box.get(key));
      final savedAt = entry['timestamp'] as int;
      final rawData = entry['data'];

      final now = DateTime.now().millisecondsSinceEpoch;
      final ttl =
          validDuration?.inMilliseconds ??
          const Duration(hours: 24).inMilliseconds;

      if (now - savedAt < ttl) {
        if (rawData is String) {
          return (T == String ? rawData : jsonDecode(rawData)) as T;
        }
        return rawData as T;
      } else {
        if (deleteIfExpired) {
          _box.delete(key);
        }
      }
    } catch (_) {
      if (deleteIfExpired) {
        _box.delete(key);
      }
    }
    return null;
  }

  Future<void> put(String key, dynamic data) async {
    final value = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': data is String ? data : jsonEncode(data),
    };
    await _box.put(key, value);
  }

  Future<void> clear() async => await _box.clear();
}
