import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'color_manager.dart';

class ThemeManager {
  // ─── Light Theme ────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: ColorManager.primaryColor,
    scaffoldBackgroundColor: ColorManager.backgroundColor,

    appBarTheme: const AppBarTheme(
      backgroundColor: ColorManager.backgroundColor,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: ColorManager.fontColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: ColorManager.fontColor),
    ),

    cardColor: ColorManager.cardLight,

    colorScheme: const ColorScheme.light(
      primary: ColorManager.primaryColor,
      secondary: ColorManager.goldColor,
      surface: ColorManager.surfaceLight,
      onPrimary: ColorManager.white,
      onSecondary: ColorManager.black,
      onSurface: ColorManager.fontColor,
      error: ColorManager.red,
      onError: ColorManager.white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorManager.surfaceLight,
      hintStyle: const TextStyle(color: ColorManager.gray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: ColorManager.gray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: ColorManager.gray.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: ColorManager.primaryColor),
      ),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: ColorManager.fontColor, fontSize: 16),
      bodyMedium: TextStyle(color: ColorManager.gray, fontSize: 14),
    ),
  );

  // ─── Dark Theme ──────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: ColorManager.primaryDarkColor,
    scaffoldBackgroundColor: ColorManager.backgroundDarkColor,

    appBarTheme: const AppBarTheme(
      backgroundColor: ColorManager.backgroundDarkColor,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: ColorManager.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: ColorManager.goldColor),
    ),

    cardColor: ColorManager.cardDark,

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorManager.cardDark,
      hintStyle: const TextStyle(color: ColorManager.gray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: ColorManager.primaryDarkColor),
      ),
    ),

    colorScheme: const ColorScheme.dark(
      primary: ColorManager.primaryDarkColor,
      secondary: ColorManager.goldColor,
      surface: ColorManager.surfaceDarkColor,
      onPrimary: ColorManager.black,
      onSecondary: ColorManager.black,
      onSurface: ColorManager.white,
      error: ColorManager.red,
      onError: ColorManager.white,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: ColorManager.white, fontSize: 16),
      bodyMedium: TextStyle(color: ColorManager.gray, fontSize: 14),
    ),
  );

  /// Returns the currently stored theme data based on cached preference.
  /// Prefer using [ThemeCubit] and [BlocBuilder] for reactive theme updates.
  static ThemeData getTheme() {
    // Default to light; ThemeCubit will override once loaded.
    return lightTheme;
  }
}
