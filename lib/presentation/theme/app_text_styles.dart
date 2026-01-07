import 'package:flutter/material.dart';
import 'app_dimens.dart';

class AppTextStyles {
  static const String fontFamily = 'Poppins';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppDimens.fontDisplay,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppDimens.fontSm,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle formLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppDimens.fontLg,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle formInput = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppDimens.fontLg,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppDimens.fontXs,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppDimens.fontXs,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppDimens.fontSm,
    fontWeight: FontWeight.w400,
  );
}
