import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/utils/payment_idempotency.dart';

void main() {
  group('createPaymentIdempotencyKey', () {
    test('uses type-entity-attempt-uuid format', () {
      final key = createPaymentIdempotencyKey(
        type: 'delivery',
        entityId: 123,
      );
      expect(key, startsWith('delivery-123-attempt-'));
      final uuid = key.substring('delivery-123-attempt-'.length);
      expect(
        uuid,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('generates unique keys per call', () {
      final a = createPaymentIdempotencyKey(type: 'order', entityId: 1);
      final b = createPaymentIdempotencyKey(type: 'order', entityId: 1);
      expect(a, isNot(equals(b)));
    });
  });

  group('isTransientPaymentNetworkError', () {
    test('detects timeout and connection ApiExceptions', () {
      expect(
        isTransientPaymentNetworkError(
          ApiException('Receive timeout. Please try again.'),
        ),
        isTrue,
      );
      expect(
        isTransientPaymentNetworkError(
          ApiException(
            'Connection timeout. Please check your internet connection.',
          ),
        ),
        isTrue,
      );
      expect(
        isTransientPaymentNetworkError(
          ApiException(
            'Connection error. Please check your internet connection.',
          ),
        ),
        isTrue,
      );
    });

    test('does not treat amount mismatch as transient', () {
      expect(
        isTransientPaymentNetworkError(
          ApiException(
            'Payment amount does not match the delivery total.',
            statusCode: 422,
          ),
        ),
        isFalse,
      );
    });
  });
}
