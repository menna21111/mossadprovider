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
    fontFamily: 'Tajawal',
    height: height,
    decoration: decoration,
    decorationColor: decorationColor,
  );
}

TextStyle _getTextStyle2(
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
    fontFamily: 'Tajawal',
    height: height,
    decoration: decoration,
    decorationColor: decorationColor,
  );
}

// light style
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

// regular style
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

// medium style
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

// bold style
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

// light style
TextStyle getLightStyle2({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return _getTextStyle2(
    fontSize,
    FontWeightManager.light,
    color,
    height,
    decoration,
    decorationColor,
  );
}

// regular style
TextStyle getRegularStyle2({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return _getTextStyle2(
    fontSize,
    FontWeightManager.regular,
    color,
    height,
    decoration,
    decorationColor,
  );
}

// medium style
TextStyle getMediumStyle2({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return _getTextStyle2(
    fontSize,
    FontWeightManager.medium,
    color,
    height,
    decoration,
    decorationColor,
  );
}

// bold style
TextStyle getBoldStyle2({
  required double fontSize,
  required Color color,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return _getTextStyle2(
    fontSize,
    FontWeightManager.bold,
    color,
    height,
    decoration,
    decorationColor,
  );
}

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
