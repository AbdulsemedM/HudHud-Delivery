import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/taxi/data/models/ride_request_result.dart';

void main() {
  group('parseRideRequestResponse', () {
    test('parses documented ride request response', () {
      const json = {
        'success': true,
        'data': {
          'ride_id': 456,
          'estimated_fare': 28.75,
          'currency': 'KES',
          'status': 'searching',
          'payment_status': 'pending',
        },
      };

      final result = parseRideRequestResponse(json);
      expect(result.isValid, isTrue);
      expect(result.rideId, 456);
      expect(result.estimatedFare, 28.75);
      expect(result.currency, 'KES');
      expect(result.status, 'searching');
      expect(result.paymentStatus, 'pending');
    });

    test('parses nested ride.id legacy shape', () {
      const json = {
        'success': true,
        'data': {
          'ride': {
            'id': 99,
            'estimated_fare': '40.00',
            'currency': 'ETB',
            'status': 'searching',
          },
        },
      };

      final result = parseRideRequestResponse(json);
      expect(result.rideId, 99);
      expect(result.estimatedFare, 40.0);
      expect(result.currency, 'ETB');
    });

    test('falls back to flat id', () {
      final result = parseRideRequestResponse({'id': 7, 'currency': 'SOS'});
      expect(result.rideId, 7);
      expect(result.currency, 'SOS');
    });
  });

  group('parseRideCancelRefundResponse', () {
    test('parses refund fields from cancel response', () {
      const json = {
        'success': true,
        'message': 'Ride cancelled successfully. Refund will be processed.',
        'data': {
          'refund_amount': 28.75,
          'refund_status': 'processing',
          'estimated_time': '2-3 business days',
        },
      };

      final refund = parseRideCancelRefundResponse(json);
      expect(refund.hasRefund, isTrue);
      expect(refund.refundAmount, 28.75);
      expect(refund.refundStatus, 'processing');
      expect(refund.estimatedTime, '2-3 business days');
      expect(refund.message, contains('Refund will be processed'));

      final message = formatRideCancelRefundMessage(refund);
      expect(message, contains('28.75'));
      expect(message, contains('processing'));
      expect(message, contains('Wallet balance'));
    });

    test('formats message without refund when amount missing', () {
      final refund = parseRideCancelRefundResponse({
        'message': 'Ride cancelled successfully.',
        'data': {},
      });
      expect(refund.hasRefund, isFalse);
      expect(
        formatRideCancelRefundMessage(refund),
        'Ride cancelled successfully.',
      );
    });
  });

  group('parseRideFare', () {
    test('prefers total_fare over estimated_fare', () {
      expect(
        parseRideFare({
          'total_fare': 30.0,
          'estimated_fare': 28.75,
        }),
        30.0,
      );
      expect(parseRideCurrency({'currency': 'KES'}), 'KES');
    });
  });
}
