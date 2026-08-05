import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/data/models/create_delivery_result.dart';

void main() {
  group('parseCreateDeliveryResponse', () {
    test('parses documented delivery payment create response', () {
      const json = {
        'success': true,
        'data': {
          'delivery_id': 789,
          'total_amount': 500.00,
          'currency': 'KES',
          'tracking_number': 'HUD123456789',
          'status': 'pending_payment',
        },
      };

      final result = parseCreateDeliveryResponse(json);
      expect(result.isValid, isTrue);
      expect(result.deliveryId, 789);
      expect(result.totalAmount, 500.0);
      expect(result.currency, 'KES');
      expect(result.trackingNumber, 'HUD123456789');
      expect(result.status, 'pending_payment');
      expect(result.isPendingPayment, isTrue);
    });

    test('parses nested delivery.id legacy shape', () {
      const json = {
        'success': true,
        'data': {
          'delivery': {
            'id': 99,
            'currency': 'ETB',
            'estimated_cost': '250.50',
            'tracking_number': 'TRK99',
          },
        },
      };

      final result = parseCreateDeliveryResponse(json);
      expect(result.deliveryId, 99);
      expect(result.totalAmount, 250.50);
      expect(result.currency, 'ETB');
      expect(result.trackingNumber, 'TRK99');
    });

    test('falls back to flat id and order_id', () {
      final flat = parseCreateDeliveryResponse({
        'id': 7,
        'currency': 'SOS',
        'total_amount': 100,
      });
      expect(flat.deliveryId, 7);
      expect(flat.currency, 'SOS');
      expect(flat.totalAmount, 100);

      final byOrderId = parseCreateDeliveryResponse({'order_id': 55});
      expect(byOrderId.deliveryId, 55);

      final empty = parseCreateDeliveryResponse(null, fallbackDeliveryId: 42);
      expect(empty.deliveryId, 42);
      expect(empty.totalAmount, isNull);
    });

    test('prefers total_amount over estimated_cost', () {
      final result = parseCreateDeliveryResponse({
        'data': {
          'delivery_id': 1,
          'total_amount': 500,
          'estimated_cost': 999,
          'currency': 'KES',
        },
      });
      expect(result.totalAmount, 500);
    });
  });

  group('expectedDeliveryStatusAfterPayment', () {
    test('maps methods to delivery statuses', () {
      expect(expectedDeliveryStatusAfterPayment('wallet'), 'paid');
      expect(expectedDeliveryStatusAfterPayment('cash_on_delivery'), 'confirmed');
      expect(expectedDeliveryStatusAfterPayment('waafi'), 'processing');
      expect(expectedDeliveryStatusAfterPayment('edahab'), 'processing');
      expect(expectedDeliveryStatusAfterPayment('sahay'), 'processing');
      expect(expectedDeliveryStatusAfterPayment('ebirr'), 'processing');
    });
  });
}
