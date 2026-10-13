import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

/// Colors for the animated splash screen (matches HTML mock CSS vars).
class SplashColors {
  SplashColors._();

  // Dark palette
  static const Color bgDeep = AppColors.darkBackground;
  static const Color bgOuter = Color(0xFF0A0614);
  static const Color orange = AppColors.primaryLightColor;
  static const Color orangeDeep = AppColors.brandOrange;
  static const Color violet = AppColors.brandIndigoBright;
  static const Color violetDeep = AppColors.brandIndigo;
  static const Color textPrimary = AppColors.darkTextPrimary;
  static const Color textMuted = AppColors.darkTextHint;

  // Light palette
  static const Color lightBgDeep = AppColors.lightBackground;
  static const Color lightBgOuter = AppColors.lightSurface;
  static const Color lightTextPrimary = AppColors.lightTextPrimary;
  static const Color lightTextMuted = AppColors.lightTextSecondary;

  static Color bgDeepOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgDeep : lightBgDeep;

  static Color bgOuterOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgOuter : lightBgOuter;

  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimary
          : lightTextPrimary;

  static Color textMutedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textMuted
          : lightTextMuted;
}
