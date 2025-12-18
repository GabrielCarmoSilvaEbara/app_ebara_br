import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadManager {
  static const int maxCacheMb = 200;
  static const Duration cacheTTL = Duration(days: 30);

  static final Map<String, String> _taskIds = {};
  static final Map<String, StreamController<Map<String, dynamic>>> _streams =
      {};

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await FlutterDownloader.initialize(debug: false);
    FlutterDownloader.registerCallback(_callback);
    await _restore();
    await _cleanCache();
  }

  static Stream<Map<String, dynamic>> watch(String url) {
    return _streams.putIfAbsent(url, () => StreamController.broadcast()).stream;
  }

  static Future<void> enqueue({
    required String url,
    required String fileName,
  }) async {
    if (!await _permission()) return;

    final dir = await _dir();
    final file = File('${dir.path}/$fileName');

    if (await file.exists()) {
      OpenFilex.open(file.path);
      return;
    }

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: dir.path,
      fileName: fileName,
      showNotification: false,
      openFileFromNotification: false,
      saveInPublicStorage: false,
    );

    if (taskId == null) return;

    _taskIds[url] = taskId;
    _emit(url, 0, false, false, false);
    await _persist();
  }

  static Future<void> pause(String url) async {
    final id = _taskIds[url];
    if (id == null) return;
    await FlutterDownloader.pause(taskId: id);
  }

  static Future<void> resume(String url) async {
    final id = _taskIds[url];
    if (id == null) return;

    final newId = await FlutterDownloader.resume(taskId: id);
    if (newId != null) {
      _taskIds[url] = newId;
      await _persist();
    }
  }

  @pragma('vm:entry-point')
  static void _callback(String id, int status, int progress) {
    final taskStatus = DownloadTaskStatus.values[status];

    _taskIds.forEach((url, taskId) {
      if (taskId != id) return;

      final running = taskStatus == DownloadTaskStatus.running;
      final paused = taskStatus == DownloadTaskStatus.paused;
      final completed = taskStatus == DownloadTaskStatus.complete;

      _emit(url, progress / 100, running, paused, completed);

      if (completed) {
        _openFile(url);
      }
    });
  }

  static void _emit(
    String url,
    double progress,
    bool running,
    bool paused,
    bool completed,
  ) {
    _streams[url]?.add({
      'progress': progress,
      'running': running,
      'paused': paused,
      'completed': completed,
    });
  }

  static Future<void> _openFile(String url) async {
    final dir = await _dir();
    final tasks = await FlutterDownloader.loadTasks();

    if (tasks == null) return;

    final task = tasks
        .where((t) => t.taskId == _taskIds[url])
        .cast<DownloadTask?>()
        .firstWhere((t) => t != null, orElse: () => null);

    if (task != null && task.filename != null) {
      OpenFilex.open('${dir.path}/${task.filename}');
    }
  }

  static Future<Directory> _dir() async {
    if (Platform.isIOS) return getApplicationDocumentsDirectory();
    final d = await getExternalStorageDirectory();
    return d ?? getApplicationDocumentsDirectory();
  }

  static Future<bool> _permission() async {
    if (Platform.isIOS) return true;
    return (await Permission.storage.request()).isGranted;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('downloads_bg', jsonEncode(_taskIds));
  }

  static Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('downloads_bg');
    if (raw == null) return;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    map.forEach((k, v) => _taskIds[k] = v);
  }

  static Future<void> _cleanCache() async {
    final dir = await _dir();
    final files = dir.listSync().whereType<File>().toList();

    int total = 0;
    for (final f in files) {
      final stat = await f.stat();
      total += stat.size;

      if (DateTime.now().difference(stat.modified) > cacheTTL) {
        await f.delete();
      }
    }

    if (total <= maxCacheMb * 1024 * 1024) return;

    files.sort(
      (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
    );

    for (final f in files) {
      await f.delete();
      total -= await f.length();
      if (total <= maxCacheMb * 1024 * 1024) break;
    }
  }

  static Future<bool> existsOnDisk(String fileName) async {
    final dir = await _dir();
    final file = File('${dir.path}/$fileName');
    return file.exists();
  }

  static Future<void> open(String fileName) async {
    final dir = await _dir();
    final file = File('${dir.path}/$fileName');

    if (await file.exists()) {
      await OpenFilex.open(file.path);
    }
  }
}
