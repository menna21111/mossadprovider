import 'package:flutter/material.dart';

class MosaedColors {
  static const Color primary = Color(0xFF994700);
  static const Color primaryContainer = Color(0xFFE87C2E);
  static const Color onPrimaryContainer = Color(0xFF532400);
  static const Color primaryFixed = Color(0xFFFFDBC8);
  static const Color primaryDark = Color(0xFF743500);
  static const Color background = Color(0xFFFCF9F8);
  static const Color surface = Color(0xFFFCF9F8);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F3F2);
  static const Color inputFill = Color(0xFFF6F3F2);
  static const Color border = Color(0xFFDDC1B2);
  static const Color outlineVariant = Color(0xFFDDC1B2);
  static const Color textPrimary = Color(0xFF1C1B1B);
  static const Color textSecondary = Color(0xFF5E5E5E);
  static const Color textHint = Color(0xFF897266);
  static const Color onSurfaceVariant = Color(0xFF564338);
  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0xFFECFDF3);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color cardBorder = Color(0xFFFFDBC8);
  static const Color shieldBg = Color(0xFFFFF7ED);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];
}
