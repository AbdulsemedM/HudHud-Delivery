import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/products/model/popular_product_model.dart';

void main() {
  test('parses wrapped popular products response', () {
    final result = PopularProductsResult.fromResponseData({
      'success': true,
      'data': [
        {
          'id': 1,
          'vendor_id': '7',
          'category_id': '1',
          'name': 'Gold ring',
          'price': '1500.00',
          'image_path':
              'https://hudapi.mbitrix.com/storage/39/conversions/tourmaline-ring-1-medium.jpg',
          'formatted_price': '1,500.00',
          'current_price': '1500.00',
          'is_available': true,
          'status': 'active',
          'total_orders': '1',
          'popularity_score': 100,
          'vendor_shop': {
            'id': 1,
            'shop_name': 'Vendor 1 shop',
            'delivery_fee': '50.00',
            'average_rating': 0,
            'logo_path':
                'https://hudapi.mbitrix.com/storage/38/conversions/logo-medium.jpg',
          },
        },
      ],
      'meta': {
        'period': 'month',
      },
    });

    expect(result.products, hasLength(1));
    expect(result.products.first.product.name, 'Gold ring');
    expect(result.products.first.shopName, 'Vendor 1 shop');
    expect(result.products.first.shopId, 1);
    expect(result.products.first.deliveryFee, 50);
    expect(result.meta?['period'], 'month');
  });

  // The API now sends the fee calculated from the customer's location, with
  // decimals, or null when it cannot be calculated.
  Map<String, dynamic> withShopFee(Object? fee) => {
        'data': [
          {
            'id': 9,
            'name': 'Tibs',
            'price': '300.00',
            'status': 'active',
            'vendor_shop': {'id': 3, 'shop_name': 'Shop', 'delivery_fee': fee},
          },
        ],
      };

  test('keeps the decimals of the calculated delivery fee', () {
    final result = PopularProductsResult.fromResponseData(withShopFee(85.47));
    expect(result.products.first.deliveryFee, 85.47);
  });

  test('a fee the API could not calculate stays unknown, not zero', () {
    final result = PopularProductsResult.fromResponseData(withShopFee(null));
    expect(result.products.first.deliveryFee, isNull);
  });
}
