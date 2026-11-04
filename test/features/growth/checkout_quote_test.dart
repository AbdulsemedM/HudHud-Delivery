import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/growth/data/models/checkout_quote.dart';
import 'package:hudhud_delivery/features/growth/data/models/checkout_quote_request.dart';

void main() {
  group('CheckoutQuote', () {
    test('parses the contract payload', () {
      final quote = CheckoutQuote.tryParseResponseBody({
        'success': true,
        'data': {
          'subtotal': 850.00,
          'delivery_fee': 60.00,
          'delivery_fee_before_discounts': 60.00,
          'free_delivery': {
            'enabled': true,
            'threshold': 1000.00,
            'applied': false,
            'remaining': 150.00,
          },
          'coupon': {
            'code': 'WELCOME',
            'valid': true,
            'discount_amount': 50.00,
            'free_delivery': false,
            'message': null,
          },
          'points': {
            'balance': 340,
            'requested': 200,
            'redeemed': 200,
            'discount_amount': 20.00,
            'max_redeemable': 300,
          },
          'total': 880.00,
          'currency': 'ETB',
        },
      });

      expect(quote, isNotNull);
      final q = quote!;
      expect(q.subtotal, 850.0);
      expect(q.deliveryFee, 60.0);
      expect(q.deliveryFeeBeforeDiscounts, 60.0);
      expect(q.deliveryFeeDiscounted, isFalse);
      expect(q.isDeliveryFree, isFalse);
      expect(q.total, 880.0);
      expect(q.currency, 'ETB');

      expect(q.freeDelivery.enabled, isTrue);
      expect(q.freeDelivery.applied, isFalse);
      expect(q.freeDelivery.remaining, 150.0);
      expect(q.freeDelivery.showHint, isTrue);
      expect(q.freeDelivery.progress, closeTo(0.85, 1e-9));

      expect(q.coupon!.code, 'WELCOME');
      expect(q.coupon!.valid, isTrue);
      expect(q.couponDiscount, 50.0);
      expect(q.coupon!.message, isNull);

      expect(q.points.balance, 340);
      expect(q.points.requested, 200);
      expect(q.points.redeemed, 200);
      expect(q.points.maxRedeemable, 300);
      expect(q.pointsDiscount, 20.0);
    });

    test('null coupon and free delivery applied', () {
      final q = CheckoutQuote.fromJson({
        'subtotal': 1200,
        'delivery_fee': 0,
        'delivery_fee_before_discounts': 60,
        'free_delivery': {
          'enabled': true,
          'threshold': 1000,
          'applied': true,
          'remaining': 0,
        },
        'coupon': null,
        'points': {
          'balance': 0,
          'requested': 0,
          'redeemed': 0,
          'discount_amount': 0,
          'max_redeemable': 0,
        },
        'total': 1200,
      });
      expect(q.coupon, isNull);
      expect(q.couponDiscount, 0);
      expect(q.isDeliveryFree, isTrue);
      expect(q.deliveryFeeDiscounted, isTrue);
      expect(q.freeDelivery.showHint, isFalse);
      expect(q.freeDelivery.progress, 1.0);
      expect(q.currency, 'ETB');
    });

    test('invalid coupon contributes no discount', () {
      final q = CheckoutQuote.fromJson({
        'subtotal': 100,
        'delivery_fee': 40,
        'coupon': {
          'code': 'X',
          'valid': false,
          'discount_amount': 0,
          'message': 'Expired',
        },
        'total': 140,
      });
      expect(q.coupon!.valid, isFalse);
      expect(q.coupon!.message, 'Expired');
      expect(q.couponDiscount, 0);
      // Missing before-discount fee defaults to the fee itself.
      expect(q.deliveryFeeBeforeDiscounts, 40);
      expect(q.points.maxRedeemable, 0);
    });

    test('rejects non-quote bodies', () {
      expect(CheckoutQuote.tryParseResponseBody(null), isNull);
      expect(
        CheckoutQuote.tryParseResponseBody({'success': false}),
        isNull,
      );
      expect(
        CheckoutQuote.tryParseResponseBody({
          'success': true,
          'data': {'foo': 1},
        }),
        isNull,
      );
    });
  });

  group('pointsToEtb', () {
    test('converts whole units only', () {
      expect(pointsToEtb(340, redeemPoints: 100, redeemValue: 10), 30);
      expect(pointsToEtb(99, redeemPoints: 100, redeemValue: 10), 0);
      expect(pointsToEtb(100, redeemPoints: 0, redeemValue: 10), 0);
    });
  });

  group('CheckoutQuoteRequest', () {
    test('mirrors order-create fields plus coupon and points', () {
      final body = const CheckoutQuoteRequest(
        vendorId: 12,
        branchId: 3,
        items: [
          {'product_id': 88, 'quantity': 2, 'variant_id': '5'},
          {'product_id': 90, 'quantity': 1, 'variant_id': null},
        ],
        deliveryAddress: 'Bole',
        deliveryLatitude: 8.99,
        deliveryLongitude: 38.78,
        couponCode: ' WELCOME ',
        redeemPoints: 200,
      ).toJson();

      expect(body['vendor_id'], 12);
      expect(body['branch_id'], 3);
      expect(body['delivery_location'], 'Bole');
      expect(body['delivery_latitude'], 8.99);
      expect(body['delivery_longitude'], 38.78);
      expect(body['service_type'], 'restaurant');
      expect(body['coupon_code'], 'WELCOME');
      expect(body['redeem_points'], 200);
      final items = body['items'] as List;
      expect(items.first, {'product_id': 88, 'quantity': 2, 'variant_id': 5});
      expect(items.last, {'product_id': 90, 'quantity': 1});
      expect(body.containsKey('discount_amount'), isFalse);
      expect(body.containsKey('total'), isFalse);
    });

    test('omits empty coupon and zero points', () {
      final body = const CheckoutQuoteRequest(
        vendorId: 1,
        items: [
          {'product_id': 1, 'quantity': 1},
        ],
        deliveryAddress: 'A',
        deliveryLatitude: 1,
        deliveryLongitude: 2,
        couponCode: '  ',
        redeemPoints: 0,
      ).toJson();
      expect(body.containsKey('coupon_code'), isFalse);
      expect(body.containsKey('redeem_points'), isFalse);
      expect(body.containsKey('branch_id'), isFalse);
    });
  });
}
