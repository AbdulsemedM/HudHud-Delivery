import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_item_model.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_list_result.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_share_result.dart';

void main() {
  group('WishlistItemModel', () {
    test('parses list item with nested product and price drop', () {
      const json = {
        'id': 42,
        'user_id': 7,
        'product_id': 101,
        'vendor_id': 3,
        'notes': 'Gift idea',
        'created_at': '2025-01-15T10:00:00Z',
        'updated_at': '2025-01-16T12:00:00Z',
        'is_in_stock': true,
        'price_drop': {
          'product_id': 101,
          'product_name': 'Gold ring',
          'original_price': '2000.00',
          'current_price': '1500.00',
          'has_dropped': true,
          'drop_percentage': 25,
          'savings': 500,
        },
        'product': {
          'id': 101,
          'name': 'Gold ring',
          'price': '1500.00',
          'is_available': true,
          'status': 'active',
        },
      };

      final item = WishlistItemModel.fromJson(json);
      expect(item.id, 42);
      expect(item.userId, 7);
      expect(item.productId, 101);
      expect(item.vendorId, 3);
      expect(item.notes, 'Gift idea');
      expect(item.isInStock, isTrue);
      expect(item.priceDrop?.hasDropped, isTrue);
      expect(item.priceDrop?.dropPercentage, 25);
      expect(item.product?.name, 'Gold ring');
    });

    test('parses add/update response shape', () {
      const json = {
        'id': 99,
        'user_id': 1,
        'product_id': 55,
        'notes': 'Birthday',
        'is_in_stock': false,
      };

      final item = WishlistItemModel.fromJson(json);
      expect(item.id, 99);
      expect(item.productId, 55);
      expect(item.notes, 'Birthday');
      expect(item.isInStock, isFalse);
    });
  });

  group('WishlistListResult', () {
    test('parses paginated wishlist response', () {
      const json = {
        'success': true,
        'data': {
          'current_page': 1,
          'last_page': 3,
          'total': 25,
          'data': [
            {
              'id': 1,
              'user_id': 2,
              'product_id': 10,
              'product': {'id': 10, 'name': 'Item A'},
            },
            {
              'id': 2,
              'user_id': 2,
              'product_id': 11,
              'product': {'id': 11, 'name': 'Item B'},
            },
          ],
        },
        'vendor_groups': [
          {'vendor_id': 5, 'vendor_name': 'Shop', 'item_count': 2},
        ],
        'total_items': 25,
      };

      final result = WishlistListResult.fromResponseData(json);
      expect(result.items.length, 2);
      expect(result.currentPage, 1);
      expect(result.lastPage, 3);
      expect(result.total, 25);
      expect(result.totalItems, 25);
      expect(result.hasMore, isTrue);
      expect(result.vendorGroups.length, 1);
      expect(result.vendorGroups.first.vendorName, 'Shop');
    });

    test('parses empty list', () {
      const json = {
        'data': {
          'current_page': 1,
          'last_page': 1,
          'total': 0,
          'data': <dynamic>[],
        },
      };

      final result = WishlistListResult.fromResponseData(json);
      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
    });
  });

  group('WishlistShareResult', () {
    test('parses share response', () {
      const json = {
        'share_token': 'abc123',
        'share_url': 'https://example.com/wishlist/shared/abc123',
        'expires_at': '2025-02-01T00:00:00Z',
      };

      final result = WishlistShareResult.fromJson(json);
      expect(result.shareToken, 'abc123');
      expect(result.shareUrl, contains('abc123'));
      expect(result.expiresAt, isNotNull);
    });
  });

  group('WishlistPriceDropsResult', () {
    test('parses price drops with items', () {
      const json = {
        'total_drops': 2,
        'notifications_sent': 1,
        'data': [
          {
            'id': 5,
            'user_id': 1,
            'product_id': 20,
            'price_drop': {'has_dropped': true, 'product_id': 20},
          },
        ],
      };

      final result = WishlistPriceDropsResult.fromResponse(json);
      expect(result.totalDrops, 2);
      expect(result.notificationsSent, 1);
      expect(result.items.length, 1);
      expect(result.items.first.priceDrop?.hasDropped, isTrue);
    });

    test('parses empty price drops', () {
      const json = {
        'total_drops': 0,
        'data': <dynamic>[],
      };

      final result = WishlistPriceDropsResult.fromResponse(json);
      expect(result.totalDrops, 0);
      expect(result.items, isEmpty);
    });
  });
}
