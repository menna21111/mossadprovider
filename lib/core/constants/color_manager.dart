import 'package:flutter/material.dart';

class ColorManager {
  // ─── Light Mode ────────────────────────────────────────────────
  static const Color primaryLightColor = Color(0xFFE07A3A);
  static const Color secondaryLightColor = Color(0xFFF59E0B);
  static const Color backgroundLightColor = Color(0xFFF5F7FA);
  static const Color surfaceLightColor = Color(0xFFFFFFFF); // surface
  static const Color textHeadingLightColor = Color(0xFF212121); // textHeading
  static const Color textBodyLightColor = Color(0xFF475569); // textBody
  static const Color successLightColor = Color(0xFF4CAF50); // success

  // ─── Keep old light constants so that old UI files don't break until refactored
  static const Color primaryColor = primaryLightColor;
  static const Color backgroundColor = backgroundLightColor;
  static const Color fontColor = textHeadingLightColor;
  static const Color surfaceLight = surfaceLightColor;
  static const Color cardLight = surfaceLightColor;

  // ─── Dark Mode ─────────────────────────────────────────────────
  static const Color primaryDarkColor = Color(0xFF0D59F2);
  static const Color backgroundDarkColor = Color(0xFF0F172A);
  static const Color surfaceDarkColor = Color(0xFF1C2642);
  static const Color cardDark = Color(0xFF1C2642);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color successDark = Color(0xFF22C55E);

  // ─── Aliases kept for backward-compat ──────────────────────────
  /// Same as [backgroundDarkColor] — used in screens that imported this directly
  static const Color backgroundDark = backgroundDarkColor;

  /// Same as [surfaceDarkColor]
  static const Color surfaceDark = surfaceDarkColor;

  // ─── Accent / Brand ────────────────────────────────────────────
  static const Color goldColor = Color(0xFF0D59F2);

  /// Alias for [goldColor]
  static const Color gold = goldColor;

  // ─── Semantic accents (same in both modes) ──────────────────────
  static const Color primary = primaryColor; // convenience alias
  static const Color successGreen = Color(0xFF22C55E);

  // ─── Neutrals ──────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFF9CA3AF);
  static const Color greyBorder = Color(0xFF6B7280);
  static const Color red = Color(0xFFEF4444);
}

// ─────────────────────────────────────────────────────────────────────────────
// Extension — access theme-aware colors from any BuildContext
// Usage:  context.appColors.background
// ─────────────────────────────────────────────────────────────────────────────
extension AppColorsX on BuildContext {
  AppColors get appColors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AppColors.dark() : AppColors.light();
  }
}

class AppColors {
  final Color background;
  final Color surface;
  final Color card;
  final Color primary;
  final Color textprimiry;
  final Color onPrimary;
  final Color onBackground;
  final Color onSurface;
  final Color secondary;
  final Color gold;
  final Color gray;
  final Color red;
  final Color bordercolor;
  final Color successGreen;

  const AppColors._({
    required this.background,
    required this.surface,
    required this.textprimiry,
    required this.card,
    required this.primary,
    required this.onPrimary,
    required this.onBackground,
    required this.onSurface,
    required this.secondary,
    required this.gold,
    required this.gray,
    required this.red,
    required this.successGreen,
    required this.bordercolor,
  });

  factory AppColors.light() => const AppColors._(
    textprimiry: ColorManager.black,
    bordercolor: ColorManager.white,
    background: ColorManager.white,
    surface: ColorManager.surfaceLightColor,
    card: ColorManager.surfaceLightColor,
    primary: ColorManager.black,
    onPrimary: ColorManager.white,
    onBackground: ColorManager.textHeadingLightColor,
    onSurface: ColorManager.textHeadingLightColor,
    secondary: ColorManager.secondaryLightColor,
    gold:
        ColorManager
            .goldColor, // Usually stays the same gold brand flavor unless requested
    gray: ColorManager.textBodyLightColor, // Used for secondary text
    red: ColorManager.red,
    successGreen: ColorManager.successLightColor,
  );

  factory AppColors.dark() => const AppColors._(
    textprimiry: ColorManager.white,
    bordercolor: ColorManager.white,
    background: ColorManager.backgroundDarkColor,
    surface: ColorManager.surfaceDarkColor,
    card: ColorManager.cardDark,
    primary: ColorManager.white,
    onPrimary: ColorManager.black,
    onBackground: ColorManager.textPrimaryDark,
    onSurface: ColorManager.textPrimaryDark,
    secondary: ColorManager.goldColor, // Using gold for secondary as fallback
    gold: ColorManager.goldColor, // Keep brand gold
    gray: ColorManager.textSecondaryDark,
    red: ColorManager.red,
    successGreen: ColorManager.successDark,
  );
}
