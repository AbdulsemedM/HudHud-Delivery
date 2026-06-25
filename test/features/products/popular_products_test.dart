import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/products/model/popular_product_model.dart';

void main() {
  group('PopularProductModel', () {
    test('parses popular products API response', () {
      const json = {
        'success': true,
        'data': [
          {
            'id': 1,
            'vendor_id': '7',
            'category_id': '1',
            'name': 'Gold ring',
            'price': '1500.00',
            'image_path':
                'https://example.com/storage/39/conversions/tourmaline-ring-1-medium.jpg',
            'preparation_time': '15',
            'is_available': true,
            'status': 'active',
            'total_orders': '1',
            'total_quantity_sold': '2',
            'popularity_score': 100,
            'formatted_price': '1,500.00',
            'current_price': '1500.00',
            'vendor_shop': {
              'id': 1,
              'shop_name': 'Vendor 1 shop',
              'delivery_fee': '50.00',
              'avg_preparation_time': 20,
              'average_rating': 4.5,
              'logo_path': 'https://example.com/logo-medium.jpg',
            },
          },
        ],
      };

      final items = PopularProductModel.parseResponse(json);
      expect(items.length, 1);
      expect(items.first.displayName, 'Gold ring');
      expect(items.first.totalOrders, 1);
      expect(items.first.vendorShopName, 'Vendor 1 shop');
      expect(items.first.shopRating, 4.5);
      expect(items.first.deliveryFeeAmount, 50);
      expect(items.first.promoText, '1 orders');
      expect(items.first.secondaryLine, contains('1,500.00'));
      expect(items.first.secondaryLine, contains('Vendor 1 shop'));
    });
  });
}
