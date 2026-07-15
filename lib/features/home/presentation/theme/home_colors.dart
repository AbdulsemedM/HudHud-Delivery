import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/splash/presentation/theme/splash_colors.dart';

/// Always-dark Home hub tokens (aligned with splash / profile chrome).
class HomeColors {
  HomeColors._();

  static const Color background = SplashColors.bgDeep;
  static const Color backgroundOuter = SplashColors.bgOuter;
  static const Color surface = Color(0xFF1D1224);
  static const Color surfaceElevated = Color(0xFF2A1C34);
  static const Color border = Color(0x17FFFFFF); // ~9% white
  static const Color orange = SplashColors.orange;
  static const Color violet = SplashColors.violet;
  static const Color textPrimary = SplashColors.textPrimary;
  static const Color textMuted = SplashColors.textMuted;
  static const Color textSecondary = Color(0xFFB6ADC6);

  static ThemeData darkTheme(ThemeData base) {
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: orange,
        secondary: violet,
        surface: surface,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onSurfaceVariant: textMuted,
        outline: Color(0xFF2A2438),
        outlineVariant: Color(0xFF2A2438),
      ).copyWith(
        surfaceContainerHighest: surfaceElevated,
        surfaceContainerHigh: surfaceElevated,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      dividerColor: textMuted.withValues(alpha: 0.35),
    );
  }
}
