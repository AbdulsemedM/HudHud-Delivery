import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/checkout/data/models/create_order_result.dart';

void main() {
  group('parseCreateOrderResponse', () {
    test('parses documented order payment create response', () {
      const json = {
        'success': true,
        'data': {
          'order_id': 123,
          'total_amount': 1500.00,
          'currency': 'KES',
          'status': 'pending_payment',
        },
      };

      final result = parseCreateOrderResponse(json);
      expect(result.isValid, isTrue);
      expect(result.orderId, 123);
      expect(result.totalAmount, 1500.0);
      expect(result.currency, 'KES');
      expect(result.status, 'pending_payment');
    });

    test('parses nested order.id legacy shape', () {
      const json = {
        'success': true,
        'data': {
          'order': {
            'id': 99,
            'currency': 'ETB',
            'total_amount': '250.50',
          },
        },
      };

      final result = parseCreateOrderResponse(json);
      expect(result.orderId, 99);
      expect(result.totalAmount, 250.50);
      expect(result.currency, 'ETB');
    });

    test('falls back to flat id and event order id', () {
      final flat = parseCreateOrderResponse({'id': 7, 'currency': 'SOS'});
      expect(flat.orderId, 7);
      expect(flat.currency, 'SOS');

      final empty = parseCreateOrderResponse(null, fallbackOrderId: 42);
      expect(empty.orderId, 42);
      expect(empty.totalAmount, isNull);
    });

    test('prefers total_amount for initiate amount source', () {
      final result = parseCreateOrderResponse({
        'data': {
          'order_id': 1,
          'total_amount': 1500,
          'amount': 999,
          'currency': 'KES',
        },
      });
      expect(result.totalAmount, 1500);
    });
  });

  group('expectedOrderStatusAfterPayment', () {
    test('maps methods to order statuses', () {
      expect(expectedOrderStatusAfterPayment('wallet'), 'paid');
      expect(expectedOrderStatusAfterPayment('cash_on_delivery'), 'confirmed');
      expect(expectedOrderStatusAfterPayment('waafi'), 'processing');
      expect(expectedOrderStatusAfterPayment('edahab'), 'processing');
      expect(expectedOrderStatusAfterPayment('sahay'), 'processing');
      expect(expectedOrderStatusAfterPayment('ebirr'), 'processing');
    });
  });
}
