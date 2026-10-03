import 'package:flutter/material.dart';

import 'font_manager.dart';

TextStyle _getTextStyle(
  double fontSize,
  FontWeight fontWeight,
  Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
) {
  return TextStyle(
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    fontFamily: FontConstants.fontFamily, // IBMPlexSansArabic
    height: height,
    decoration: decoration,
    decorationColor: decorationColor,
  );
}

/// ExtraLight — IBMPlexSansArabic-ExtraLight.ttf (w200)
TextStyle getExtraLightStyle({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return _getTextStyle(
    fontSize,
    FontWeightManager.extraLight,
    color,
    height,
    decoration,
    decorationColor,
  );
}

TextStyle getLightStyle({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return _getTextStyle(
    fontSize,
    FontWeightManager.light,
    color,
    height,
    decoration,
    decorationColor,
  );
}

TextStyle getRegularStyle({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return _getTextStyle(
    fontSize,
    FontWeightManager.regular,
    color,
    height,
    decoration,
    decorationColor,
  );
}

TextStyle getMediumStyle({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return _getTextStyle(
    fontSize,
    FontWeightManager.medium,
    color,
    height,
    decoration,
    decorationColor,
  );
}

TextStyle getSemiBoldStyle({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return _getTextStyle(
    fontSize,
    FontWeightManager.semiBold,
    color,
    height,
    decoration,
    decorationColor,
  );
}

TextStyle getBoldStyle({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return _getTextStyle(
    fontSize,
    FontWeightManager.bold,
    color,
    height,
    decoration,
    decorationColor,
  );
}

// Legacy aliases (same IBM family)
TextStyle getLightStyle2({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) =>
    getLightStyle(
      fontSize: fontSize,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );

TextStyle getRegularStyle2({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) =>
    getRegularStyle(
      fontSize: fontSize,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );

TextStyle getMediumStyle2({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) =>
    getMediumStyle(
      fontSize: fontSize,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );

TextStyle getBoldStyle2({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) =>
    getBoldStyle(
      fontSize: fontSize,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );

TextDirection getTextDirectionFromText(String text) {
  final arabicRegex = RegExp(r'[\u0600-\u06FF]');
  return arabicRegex.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
}

({TextDirection direction, TextAlign align}) getTextDirectionAndAlignFromText(
  String text,
) {
  final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  return (
    direction: isArabic ? TextDirection.rtl : TextDirection.ltr,
    align: isArabic ? TextAlign.right : TextAlign.left,
  );
}
