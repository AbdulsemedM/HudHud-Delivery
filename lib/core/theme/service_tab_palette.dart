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

  /// Courier — purple.
  static const Color courier = Color(0xFF7B61FF);

  /// Taxi — yellow (accent).
  static const Color taxi = Color(0xFFFFD600);

  /// Handyman — blue.
  static const Color handyman = Color(0xFF1E88E5);

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
