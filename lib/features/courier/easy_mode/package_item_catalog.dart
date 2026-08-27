import 'package:flutter/material.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Canonical package item types used by classic + Easy Mode booking.
class PackageItemCatalog {
  PackageItemCatalog._();

  /// Stable API-facing English labels (must match ConfirmDetailsScreen mapping).
  static const electronics = 'Electronics/Gadgets';
  static const documents = 'Documents';
  static const food = 'Food';
  static const clothing = 'Clothing';
  static const books = 'Books';
  static const fragile = 'Fragile';
  static const other = 'Other';

  static const easyModeIds = <String>[
    documents,
    food,
    clothing,
    electronics,
    fragile,
    other,
  ];

  static const allIds = <String>[
    electronics,
    documents,
    food,
    clothing,
    books,
    fragile,
    other,
  ];

  static IconData iconFor(String id) {
    switch (id) {
      case electronics:
        return Icons.phone_android_rounded;
      case documents:
        return Icons.description_rounded;
      case food:
        return Icons.restaurant_rounded;
      case clothing:
        return Icons.checkroom_rounded;
      case books:
        return Icons.menu_book_rounded;
      case fragile:
        return Icons.broken_image_outlined;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  static String labelFor(String id, AppLocalizations l10n) {
    switch (id) {
      case electronics:
        return l10n.itemTypeElectronics;
      case documents:
        return l10n.itemTypeDocuments;
      case food:
        return l10n.itemTypeFood;
      case clothing:
        return l10n.itemTypeClothing;
      case books:
        return l10n.itemTypeBooks;
      case fragile:
        return l10n.itemTypeFragile;
      default:
        return l10n.itemTypeOther;
    }
  }

  /// Approximate weight (kg) from pictorial size choice.
  static double weightForSize(String sizeId) {
    switch (sizeId) {
      case 'large':
        return 8;
      case 'medium':
        return 3;
      default:
        return 1;
    }
  }
}
