import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Upper home service tabs; also drives global accent while Home dashboard tab is active.
/// Order is load-bearing: HomeScreen drives an IndexedStack from `.index`,
/// so these must stay in the same order as its children and new modes are
/// APPENDED, never inserted.
enum HomeServiceMode {
  courier,
  foodGroceries,
  taxi,
  handyman,
  pharmacy,
  spareParts,
}

/// The vendor sector a mode narrows the marketplace to, or null for the
/// modes that are not a marketplace view.
extension HomeServiceModeSector on HomeServiceMode {
  String? get vendorSector => switch (this) {
        HomeServiceMode.pharmacy => 'pharmacy',
        HomeServiceMode.spareParts => 'spare_parts',
        _ => null,
      };
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

  /// Pharmacy — green, the colour the trade uses everywhere.
  static const Color pharmacy = Color(0xFF1E7A4A);

  /// Spare parts — graphite, deliberately unlike the three above so a
  /// workshop errand does not read as a food or medicine order.
  static const Color spareParts = Color(0xFF36434F);

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
      case HomeServiceMode.pharmacy:
        return pharmacy;
      case HomeServiceMode.spareParts:
        return spareParts;
    }
  }
}
