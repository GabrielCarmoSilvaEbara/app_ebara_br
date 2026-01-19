import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadService {
  final Dio _dio;

  DownloadService({Dio? dio}) : _dio = dio ?? Dio();

  Future<String?> get _localPath async {
    if (kIsWeb) return null;
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File?> _getLocalFile(String filename) async {
    final path = await _localPath;
    if (path == null) return null;
    return File('$path/$filename');
  }

  Future<bool> isFileDownloaded(String filename) async {
    if (kIsWeb) return false;
    final file = await _getLocalFile(filename);
    return file != null && await file.exists();
  }

  Future<void> openFile(String filename, String fallbackUrl) async {
    if (kIsWeb) {
      await launchUrl(Uri.parse(fallbackUrl));
      return;
    }

    final file = await _getLocalFile(filename);
    if (file != null && await file.exists()) {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        await launchUrl(Uri.parse(fallbackUrl));
      }
    } else {
      await launchUrl(Uri.parse(fallbackUrl));
    }
  }

  Future<void> downloadFile({
    required String url,
    required String filename,
    required Function(double progress) onProgress,
  }) async {
    if (kIsWeb) {
      return;
    }

    try {
      final path = await _localPath;
      if (path == null) throw Exception("Armazenamento não disponível");

      final savePath = '$path/$filename';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final double progress = received / total;
            onProgress(progress);
          }
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
