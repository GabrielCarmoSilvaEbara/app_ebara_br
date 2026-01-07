import 'package:flutter/widgets.dart';

class UiUtil {
  static int? cacheSize(BuildContext context, double size) {
    if (size <= 0) return null;
    return (size * MediaQuery.of(context).devicePixelRatio).toInt();
  }
}
