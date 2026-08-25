import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

/// Colors for auth screens (login + forgot password) in light and dark modes.
class AuthScreenColors {
  AuthScreenColors._();

  // Dark tokens
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

  // Light tokens
  static const Color lightBackground = AppColors.lightBackground;
  static const Color lightSurface = AppColors.lightSurface;
  static const Color lightSurfaceBorder = AppColors.lightBorder;
  static const Color lightTextPrimary = AppColors.lightTextPrimary;
  static const Color lightTextSecondary = AppColors.lightTextSecondary;
  static const Color lightTextMuted = AppColors.lightTextHint;

  static const List<Color> signInGradient = [orange, purple];

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? background : lightBackground;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? surface : lightSurface;

  static Color surfaceBorderOf(BuildContext context) =>
      isDark(context) ? surfaceBorder : lightSurfaceBorder;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? textPrimary : lightTextPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? textSecondary : lightTextSecondary;

  static Color textMutedOf(BuildContext context) =>
      isDark(context) ? textMuted : lightTextMuted;

  static ThemeData themeFor(BuildContext context) {
    final base = Theme.of(context);
    return isDark(context) ? darkTheme(base) : lightTheme(base);
  }

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
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: surface,
        hintColor: textSecondary,
        labelColor: textMuted,
        focusedBorderColor: orange,
      ),
      snackBarTheme: _snackBarTheme(
        backgroundColor: surface,
        textColor: textPrimary,
        borderColor: surfaceBorder,
      ),
      dialogTheme: _dialogTheme(
        backgroundColor: surface,
        borderColor: surfaceBorder,
        titleColor: textPrimary,
        contentColor: textSecondary,
      ),
      bottomSheetTheme: _bottomSheetTheme(surface),
    );
  }

  static ThemeData lightTheme(ThemeData base) {
    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryColor,
        secondary: purple,
        surface: lightSurface,
        onPrimary: AppColors.lightOnPrimary,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        outline: lightSurfaceBorder,
        outlineVariant: lightSurfaceBorder,
        error: AppColors.errorColor,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      dividerColor: lightTextSecondary.withValues(alpha: 0.35),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: AppColors.lightInputFill,
        hintColor: lightTextSecondary,
        labelColor: lightTextMuted,
        focusedBorderColor: AppColors.primaryColor,
      ),
      snackBarTheme: _snackBarTheme(
        backgroundColor: lightSurface,
        textColor: lightTextPrimary,
        borderColor: lightSurfaceBorder,
      ),
      dialogTheme: _dialogTheme(
        backgroundColor: lightSurface,
        borderColor: lightSurfaceBorder,
        titleColor: lightTextPrimary,
        contentColor: lightTextSecondary,
      ),
      bottomSheetTheme: _bottomSheetTheme(lightSurface),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color hintColor,
    required Color labelColor,
    required Color focusedBorderColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      labelStyle: TextStyle(color: labelColor),
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
        borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.errorColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  static SnackBarThemeData _snackBarTheme({
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return SnackBarThemeData(
      backgroundColor: backgroundColor,
      contentTextStyle: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: orange,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
    );
  }

  static DialogThemeData _dialogTheme({
    required Color backgroundColor,
    required Color borderColor,
    required Color titleColor,
    required Color contentColor,
  }) {
    return DialogThemeData(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: borderColor),
      ),
      titleTextStyle: TextStyle(
        color: titleColor,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: contentColor,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  static BottomSheetThemeData _bottomSheetTheme(Color backgroundColor) {
    return BottomSheetThemeData(
      backgroundColor: backgroundColor,
      modalBackgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    );
  }
}
