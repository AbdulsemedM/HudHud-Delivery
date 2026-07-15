import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Upper home service tabs; also drives global accent while Home dashboard tab is active.
enum HomeServiceMode {
  foodGroceries,
  courier,
  taxi,
  handyman,
}

/// Brand seeds for [ColorScheme.fromSeed] per service area.
abstract final class ServiceTabPalette {
  /// Food & groceries — existing HudHud orange.
  static const Color foodGroceries = AppColors.primaryColor;

  /// Courier — violet (matches home/splash mock).
  static const Color courier = Color(0xFF9D86F7);

  /// Taxi — gold.
  static const Color taxi = Color(0xFFFFD600);

  /// Handyman — sky blue.
  static const Color handyman = Color(0xFF42A5F5);

  static Color seedFor(HomeServiceMode mode) {
    switch (mode) {
      case HomeServiceMode.foodGroceries:
        return foodGroceries;
      case HomeServiceMode.courier:
        return courier;
      case HomeServiceMode.taxi:
        return taxi;
      case HomeServiceMode.handyman:
        return handyman;
    }
  }
}
