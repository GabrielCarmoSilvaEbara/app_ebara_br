import '../constants/app_constants.dart';

extension StringExtensions on String {
  String get toEbaraIconUrl {
    if (isEmpty) return '';
    if (startsWith('http')) return this;
    return '${AppConstants.ebaraFilesUrl}/$this';
  }

  String toEbaraFileUrl(String path) {
    if (isEmpty) return '';
    if (startsWith('http')) return this;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${AppConstants.ebaraBaseUrl}/$cleanPath/$this';
  }

  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  double toDoubleSafe() {
    if (isEmpty) return 0.0;
    return double.tryParse(replaceAll(',', '.')) ?? 0.0;
  }
}
