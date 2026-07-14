import 'package:flutter/material.dart';

/// Colors for always-dark auth screens (login + forgot password).
class AuthScreenColors {
  AuthScreenColors._();

  static const Color background = Color(0xFF0D0B14);
  static const Color surface = Color(0xFF1A1625);
  static const Color surfaceBorder = Color(0xFF2A2438);
  static const Color orange = Color(0xFFF27121);
  static const Color orangeBright = Color(0xFFFF7A33);
  static const Color purple = Color(0xFF8E6CEF);
  static const Color lavender = Color(0xFFA294F9);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF706E7A);
  static const Color textMuted = Color(0xFF9A97A5);

  static const List<Color> signInGradient = [orange, purple];

  static ThemeData darkTheme(ThemeData base) {
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: orange,
        secondary: purple,
        surface: surface,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: surfaceBorder,
        outlineVariant: surfaceBorder,
        error: Color(0xFFEF5350),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      dividerColor: textSecondary.withValues(alpha: 0.35),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
