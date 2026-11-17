import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/services/cart_service.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';

void main() {
  final cart = CartService();

  CategoriesProductsModel product({
    String price = '200',
    String? discount,
    Map<String, dynamic>? options,
  }) =>
      CategoriesProductsModel(
        id: 1,
        price: price,
        discount_price: discount,
        options: options,
      );

  test('base or discount price when no options', () {
    expect(cart.unitPrice(product()), 200);
    expect(cart.unitPrice(product(discount: '150')), 150);
  });

  test('selected variant absolute price replaces base', () {
    final p = product(options: {
      'variant_id': 7,
      'variants': [
        {'id': 6, 'price': 220},
        {'id': 7, 'price': '260.50'},
      ],
    });
    expect(cart.unitPrice(p), 260.5);
  });

  test('variant price adjustment is added to base', () {
    final p = product(options: {
      'variant_id': 7,
      'variants': [
        {'id': 7, 'price_adjustment': 40},
      ],
    });
    expect(cart.unitPrice(p), 240);
  });

  test('selected add-ons are added', () {
    final p = product(options: {
      'modifier_option_ids': [11, 13],
      'modifier_groups': [
        {
          'options': [
            {'id': 11, 'price': 15},
            {'id': 12, 'price': 99},
            {'id': 13, 'additional_price': '10'},
          ],
        },
      ],
    });
    expect(cart.unitPrice(p), 225);
  });
}
