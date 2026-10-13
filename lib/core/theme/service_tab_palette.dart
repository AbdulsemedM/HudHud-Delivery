import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Upper home service tabs; also drives global accent while Home dashboard tab is active.
enum HomeServiceMode {
  courier,
  foodGroceries,
  taxi,
  handyman,
}

/// Brand seeds for [ColorScheme.fromSeed] per service area.
abstract final class ServiceTabPalette {
  /// Food & groceries — existing HudHud orange.
  static const Color foodGroceries = AppColors.primaryColor;

  /// Courier — HudHud indigo (from the logo).
  static const Color courier = AppColors.brandIndigo;

  /// Taxi — gold.
  static const Color taxi = Color(0xFFE5A000);

  /// Handyman — teal.
  static const Color handyman = Color(0xFF0E9384);

  static Color seedFor(HomeServiceMode mode) {
    switch (mode) {
      case HomeServiceMode.courier:
        return courier;
      case HomeServiceMode.foodGroceries:
        return foodGroceries;
      case HomeServiceMode.taxi:
        return taxi;
      case HomeServiceMode.handyman:
        return handyman;
    }
  }
}
