import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/categories/model/product_filter.dart';
import 'package:hudhud_delivery/l10n/app_localizations_en.dart';

CategoriesProductsModel product({
  int? prep,
  String price = '100.00',
  String? discount,
  List<String>? addons,
}) =>
    CategoriesProductsModel(
      price: price,
      discount_price: discount,
      preparation_time: prep,
      addons: addons,
    );

void main() {
  group('worthShowing', () {
    test('a one-product store shows no filters at all', () {
      // The tester's store: one shawarma that takes 45 minutes. It used to
      // show "Slow (>30 min)", a chip that could not change the list.
      expect(ProductFilter.worthShowing([product(prep: 45)]), isEmpty);
    });

    test('a chip every product matches is not shown either', () {
      expect(
        ProductFilter.worthShowing([product(prep: 10), product(prep: 5)]),
        isEmpty,
      );
    });

    test('a chip that splits the list is shown', () {
      expect(
        ProductFilter.worthShowing([product(prep: 10), product(prep: 45)]),
        [ProductFilter.quick],
      );
    });

    test('there is no slow or medium chip any more', () {
      final names = ProductFilter.values.map((f) => f.name);
      expect(names, isNot(contains('slow')));
      expect(names, isNot(contains('medium')));
    });
  });

  group('quick', () {
    test('means a stated time of 1 to 15 minutes', () {
      expect(ProductFilter.quick.matches(product(prep: 15)), isTrue);
      expect(ProductFilter.quick.matches(product(prep: 16)), isFalse);
      // Missing or 0 is "not stated", not "instant".
      expect(ProductFilter.quick.matches(product(prep: 0)), isFalse);
      expect(ProductFilter.quick.matches(product()), isFalse);
    });
  });

  group('onSale', () {
    test('needs a discount below the price', () {
      expect(ProductFilter.onSale.matches(product(discount: '80.00')), isTrue);
      // What the API sends for products with no discount.
      expect(ProductFilter.onSale.matches(product(discount: '0.00')), isFalse);
      expect(ProductFilter.onSale.matches(product(discount: '100.00')), isFalse);
      expect(ProductFilter.onSale.matches(product(discount: '')), isFalse);
      expect(ProductFilter.onSale.matches(product()), isFalse);
    });
  });

  test('apply keeps products matching every selected filter', () {
    final quickSale = product(prep: 10, discount: '50');
    final quickOnly = product(prep: 10);
    final slowSale = product(prep: 45, discount: '50');
    final all = [quickSale, quickOnly, slowSale];

    expect(ProductFilter.apply(all, []), all);
    expect(
      ProductFilter.apply(all, [ProductFilter.quick, ProductFilter.onSale]),
      [quickSale],
    );
  });

  test('labels come from the translations', () {
    final en = AppLocalizationsEn();
    expect(ProductFilter.quick.label(en), 'Ready in 15 min or less');
    expect(ProductFilter.onSale.label(en), 'On sale');
  });
}
