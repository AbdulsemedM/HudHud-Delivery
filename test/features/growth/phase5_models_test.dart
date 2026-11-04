import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/growth/data/models/checkout_quote.dart';
import 'package:hudhud_delivery/features/growth/data/models/hudhud_deep_link.dart';
import 'package:hudhud_delivery/features/growth/data/models/hudhud_set.dart';

void main() {
  group('HudHudSetsPage', () {
    // Shape of HudHudSetController::publicIndex + HudHudSetService::publicItem.
    final body = {
      'success': true,
      'data': {
        'enabled': true,
        'market': 'addis_ababa',
        'currency': 'ETB',
        'max_per_order': 2,
        'data': [
          {
            'id': 11,
            'product_id': 11,
            'name': 'Burger set',
            'description': 'Burger, fries, drink',
            'price': 450.0,
            'currency': 'ETB',
            'delivery_included': true,
            'image': {
              'thumb': 'https://cdn.example/t.jpg',
              'medium': 'https://cdn.example/m.jpg',
            },
            'image_path': 'products/11.jpg',
            'vendor': {
              'id': 77,
              'name': 'Founding Grill',
              'logo_urls': null,
              'logo_path': null,
              'is_open': true,
              'is_currently_open': false,
              'cuisine_type': 'fast_food',
            },
          },
          {'id': 11, 'product_id': 11, 'name': 'dup', 'price': 1, 'vendor': {'id': 77}},
          {'id': 12, 'name': 'no vendor', 'price': 100},
          'garbage',
        ],
        'current_page': 1,
        'last_page': 1,
        'per_page': 20,
        'total': 1,
      },
    };

    setUp(KnownHudHudSets.clear);

    test('parses items, limits and vendor owner id', () {
      final page = HudHudSetsPage.fromResponseBody(body);
      expect(page.enabled, isTrue);
      expect(page.market, 'addis_ababa');
      expect(page.maxPerOrder, 2);
      expect(page.hasItems, isTrue);
      expect(page.items, hasLength(1));
      final item = page.items.single;
      expect(item.productId, 11);
      expect(item.vendorId, 77);
      expect(item.vendorName, 'Founding Grill');
      expect(item.price, 450.0);
      expect(item.currency, 'ETB');
      expect(item.deliveryIncluded, isTrue);
      expect(item.imageUrl, 'https://cdn.example/m.jpg');
      expect(item.vendorIsOpen, isFalse);
    });

    test('disabled / empty / bad bodies render nothing', () {
      expect(
        HudHudSetsPage.fromResponseBody({
          'success': true,
          'data': {'enabled': false, 'max_per_order': 1, 'data': []},
        }).hasItems,
        isFalse,
      );
      expect(HudHudSetsPage.fromResponseBody(null).hasItems, isFalse);
      expect(
        HudHudSetsPage.fromResponseBody({'success': false}).hasItems,
        isFalse,
      );
    });

    test('remembers set product ids for checkout', () {
      final page = HudHudSetsPage.fromResponseBody(body);
      KnownHudHudSets.remember(page.items);
      expect(KnownHudHudSets.contains(11), isTrue);
      expect(KnownHudHudSets.contains(12), isFalse);
      expect(KnownHudHudSets.contains(null), isFalse);
    });
  });

  group('CheckoutQuote set block', () {
    test('parses applied set subsidy', () {
      final quote = CheckoutQuote.tryParseResponseBody({
        'success': true,
        'data': {
          'subtotal': 900,
          'items_discount': 0,
          'delivery_fee': 0,
          'delivery_fee_before_discounts': 120,
          'free_delivery': {'enabled': false},
          'coupon': null,
          'points': {'balance': 0},
          'plus': {'member': false, 'applied': false},
          'set': {
            'enabled': true,
            'eligible': true,
            'applied': true,
            'subsidy': 120,
            'cap': 150,
            'max_per_order': 2,
            'reason': null,
          },
          'total': 900,
          'currency': 'ETB',
        },
      });
      expect(quote, isNotNull);
      expect(quote!.setDeliveryIncluded, isTrue);
      expect(quote.plusApplied, isFalse);
      expect(quote.hudhudSet!.subsidy, 120);
      expect(quote.hudhudSet!.maxPerOrder, 2);
    });

    test('over max quantity is not applied and keeps the reason', () {
      final quote = CheckoutQuote.fromJson({
        'subtotal': 1800,
        'delivery_fee': 120,
        'total': 1920,
        'set': {
          'enabled': true,
          'eligible': false,
          'applied': false,
          'subsidy': 0,
          'cap': 150,
          'max_per_order': 2,
          'reason': 'over_max_quantity',
        },
      });
      expect(quote.setDeliveryIncluded, isFalse);
      expect(quote.hudhudSet!.isOverMaxQuantity, isTrue);
    });

    test('older backend without set block', () {
      final quote = CheckoutQuote.fromJson({
        'subtotal': 100,
        'delivery_fee': 50,
        'total': 150,
      });
      expect(quote.hudhudSet, isNull);
      expect(quote.setDeliveryIncluded, isFalse);
    });
  });

  group('Vendor deep links', () {
    test('parses https, app scheme and telegram forms', () {
      expect(
        HudhudDeepLink.parse(Uri.parse('https://hudhuddelivery.com/v/42'))
            ?.vendorId,
        42,
      );
      expect(
        HudhudDeepLink.parse(Uri.parse('https://www.hudhuddelivery.com/v/v42'))
            ?.vendorId,
        42,
      );
      expect(
        HudhudDeepLink.parse(Uri.parse('hudhud://vendor/42'))?.vendorId,
        42,
      );
      expect(
        HudhudDeepLink.parse(Uri.parse('hudhud://vendor/v42'))?.vendorId,
        42,
      );
      expect(
        HudhudDeepLink.parse(
          Uri.parse('https://t.me/HudHudDeliverybot?startapp=v42'),
        )?.vendorId,
        42,
      );
    });

    test('rejects malformed vendor ids', () {
      expect(HudhudDeepLink.parse(Uri.parse('hudhud://vendor/0')), isNull);
      expect(HudhudDeepLink.parse(Uri.parse('hudhud://vendor/abc')), isNull);
      expect(HudhudDeepLink.parse(Uri.parse('hudhud://order/42')), isNull);
      expect(
        HudhudDeepLink.parse(Uri.parse('https://hudhuddelivery.com/v/012')),
        isNull,
      );
      expect(
        HudhudDeepLink.parse(Uri.parse('https://t.me/SomeBot?startapp=42')),
        isNull,
      );
      expect(HudhudDeepLink.parseVendorId('v1234567890123456789'), isNotNull);
      expect(HudhudDeepLink.parseVendorId('v12345678901234567890'), isNull);
    });

    test('existing referral and order links still parse', () {
      expect(
        HudhudDeepLink.parse(Uri.parse('https://hudhuddelivery.com/r/ab12'))
            ?.referralCode,
        'AB12',
      );
      final o =
          HudhudDeepLink.parse(Uri.parse('https://hudhuddelivery.com/o/9'));
      expect(o?.orderId, 9);
      expect(o?.vendorId, isNull);
    });
  });
}
