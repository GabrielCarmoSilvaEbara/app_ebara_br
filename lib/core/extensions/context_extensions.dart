import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../localization/app_localizations.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  AppLocalizations get l10n => AppLocalizations.of(this)!;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  double get height => mediaQuery.size.height;

  double get width => mediaQuery.size.width;

  void pushNamed(
    String routeName, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    GoRouter.of(this).pushNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void pushReplacementNamed(
    String routeName, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    GoRouter.of(this).pushReplacementNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void pop([Object? result]) {
    GoRouter.of(this).pop(result);
  }

  Future<T?> showAppBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      backgroundColor: colors.surface.withValues(alpha: 0),
      isScrollControlled: isScrollControlled,
      builder: (_) => child,
    );
  }

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : colors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  TextStyle? get titleStyle => textTheme.displayLarge;
  TextStyle? get subtitleStyle => textTheme.displayMedium;
  TextStyle? get bodyStyle => textTheme.labelMedium;
  TextStyle? get bodySmall => textTheme.labelSmall?.copyWith(
    color: colors.onSurface.withValues(alpha: 0.6),
  );
}
