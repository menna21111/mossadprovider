import 'package:flutter/material.dart';

class MosaedColors {
  /// Brand orange from mossad design.
  static const Color brand = Color(0xFFF7842C);

  /// Soft peach fill.
  static const Color brandTransparent = Color(0xffFEF3EB);

  static const Color primary = Color(0xFFF7842C);
  static const Color primaryContainer = Color(0xFFF7842C);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFF5C9A8);
  /// Soft orange fill for focused / filled OTP cells.
  static const Color otpFill = Color(0xFFFFF3E8);
  static const Color primaryDark = Color(0xFFC45F12);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F3F2);
  static const Color inputFill = Color(0xFFF6F3F2);
  static const Color border = Color(0xFFE5E0DE);
  static const Color outlineVariant = Color(0xFFE5E0DE);
  static const Color fieldBorder = Color(0xFFD1D4DC);
  static const Color textPrimary = Color(0xFF1C1B22);
  static const Color textSecondary = Color(0xFF6B6875);
  static const Color textHint = Color(0xFFB0B0B0);
  static const Color onSurfaceVariant = Color(0xFF564338);
  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0xFFECFDF3);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color cardBorder = Color(0xFFFFDBC8);
  static const Color shieldBg = Color(0xFFFFF7ED);

  static double get radius12 => 12;

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];
}
