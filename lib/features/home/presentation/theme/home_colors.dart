import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/splash/presentation/theme/splash_colors.dart';

/// Home hub tokens (dark + light), aligned with splash / profile chrome.
class HomeColors {
  HomeColors._();

  // Dark tokens
  static const Color background = SplashColors.bgDeep;
  static const Color backgroundOuter = SplashColors.bgOuter;
  static const Color surface = AppColors.darkSurface;
  static const Color surfaceElevated = AppColors.darkSurfaceVariant;
  static const Color border = Color(0x17FFFFFF);
  static const Color orange = AppColors.brandOrange;
  /// Brand indigo accent. Prefer [violetOf] so dark mode stays legible.
  static const Color violet = AppColors.brandIndigo;
  static const Color violetDark = AppColors.brandIndigoBright;
  static const Color textPrimary = SplashColors.textPrimary;
  static const Color textMuted = SplashColors.textMuted;
  static const Color textSecondary = AppColors.darkTextSecondary;

  // Light tokens
  static const Color lightBackground = AppColors.lightBackground;
  static const Color lightBackgroundOuter = AppColors.lightSurface;
  static const Color lightSurface = AppColors.lightSurface;
  static const Color lightSurfaceElevated = AppColors.lightInputFill;
  static const Color lightBorder = AppColors.lightBorder;
  static const Color lightTextPrimary = AppColors.lightTextPrimary;
  static const Color lightTextMuted = AppColors.lightTextSecondary;
  static const Color lightTextSecondary = AppColors.lightTextSecondary;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? background : lightBackground;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? surface : lightSurface;

  static Color surfaceElevatedOf(BuildContext context) =>
      isDark(context) ? surfaceElevated : lightSurfaceElevated;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? textPrimary : lightTextPrimary;

  static Color textMutedOf(BuildContext context) =>
      isDark(context) ? textMuted : lightTextMuted;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? textSecondary : lightTextSecondary;

  /// Brand accent (indigo) tuned for the current brightness.
  static Color violetOf(BuildContext context) =>
      isDark(context) ? violetDark : violet;

  /// Soft accent fill behind icons / selected tiles.
  static Color violetTintOf(BuildContext context) =>
      isDark(context) ? AppColors.indigoTintDark : AppColors.indigoTint;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? border : lightBorder;

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
        secondary: violetDark,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onSurfaceVariant: textMuted,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorder,
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

  static ThemeData lightTheme(ThemeData base) {
    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryColor,
        secondary: violet,
        surface: lightSurface,
        onPrimary: AppColors.lightOnPrimary,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextMuted,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightBorder,
      ).copyWith(
        surfaceContainerHighest: lightSurfaceElevated,
        surfaceContainerHigh: lightSurfaceElevated,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      dividerColor: lightTextMuted.withValues(alpha: 0.35),
    );
  }
}
