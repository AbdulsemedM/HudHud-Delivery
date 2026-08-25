import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

/// Colors for the animated splash screen (matches HTML mock CSS vars).
class SplashColors {
  SplashColors._();

  // Dark palette
  static const Color bgDeep = Color(0xFF140B1A);
  static const Color bgOuter = Color(0xFF0C0710);
  static const Color orange = Color(0xFFFF7A3D);
  static const Color orangeDeep = Color(0xFFE85A1F);
  static const Color violet = Color(0xFF9D86F7);
  static const Color violetDeep = Color(0xFF6F56E8);
  static const Color textPrimary = Color(0xFFF8F3EE);
  static const Color textMuted = Color(0xFF726A86);

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
