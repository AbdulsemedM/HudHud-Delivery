import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// The filter chips on a store's product list.
///
/// WHAT CHANGED, and why (from the testers' report):
///
///  - Preparation time used to be three chips: "Quick (≤15 min)",
///    "Medium (16-30 min)" and "Slow (>30 min)". Nobody looks for slow food,
///    and "Slow" read as a complaint about the store or about delivery. Only
///    the useful end is kept, named for what the customer gets.
///  - "With Ingredients" is gone. It meant "the vendor typed an ingredient
///    list", which is not something a customer chooses food by.
///  - A chip now appears only when it SPLITS the list - some products match
///    and some do not. Before, any chip one product qualified for was shown,
///    so a one-product store offered filters that either did nothing or
///    emptied the page.
///  - Labels come from the translation files; they were English-only.
enum ProductFilter {
  quick,
  onSale,
  customizable,
  containsAllergens,
  nutritionInfo;

  /// "Quick" means a stated preparation time of 1 to this many minutes.
  static const int quickMinutes = 15;

  bool matches(CategoriesProductsModel p) {
    switch (this) {
      case ProductFilter.quick:
        final minutes = p.preparation_time ?? 0;
        // 0 or missing is "not stated", not "instant".
        return minutes > 0 && minutes <= quickMinutes;
      case ProductFilter.onSale:
        // A real discount: below the price. The API sends "0.00" or the full
        // price for products with no discount, and a non-empty string is not
        // a sale.
        final discount = double.tryParse(p.discount_price ?? '');
        final price = double.tryParse(p.price ?? '');
        if (discount == null || discount <= 0) return false;
        return price == null || discount < price;
      case ProductFilter.customizable:
        return p.addons?.isNotEmpty ?? false;
      case ProductFilter.containsAllergens:
        return p.allergens?.isNotEmpty ?? false;
      case ProductFilter.nutritionInfo:
        return p.calories != null || (p.protein?.isNotEmpty ?? false);
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case ProductFilter.quick:
        return l10n.productFilterQuick(quickMinutes);
      case ProductFilter.onSale:
        return l10n.productFilterOnSale;
      case ProductFilter.customizable:
        return l10n.productFilterCustomizable;
      case ProductFilter.containsAllergens:
        return l10n.productFilterContainsAllergens;
      case ProductFilter.nutritionInfo:
        return l10n.productFilterNutritionInfo;
    }
  }

  /// The chips worth showing for [products]: those that match some products
  /// but not all. Empty when none would change the list, and the Filter
  /// section is then hidden altogether.
  static List<ProductFilter> worthShowing(
    List<CategoriesProductsModel> products,
  ) {
    return ProductFilter.values.where((f) {
      final matching = products.where(f.matches).length;
      return matching > 0 && matching < products.length;
    }).toList();
  }

  /// [products] narrowed to those matching every one of [selected].
  static List<CategoriesProductsModel> apply(
    List<CategoriesProductsModel> products,
    Iterable<ProductFilter> selected,
  ) {
    if (selected.isEmpty) return products.toList();
    return products.where((p) => selected.every((f) => f.matches(p))).toList();
  }
}
