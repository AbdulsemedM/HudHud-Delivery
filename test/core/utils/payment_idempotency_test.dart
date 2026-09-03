import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/payment_idempotency.dart';

void main() {
  group('buildWalletTopUpFingerprint', () {
    test('includes method amount currency phone note', () {
      expect(
        buildWalletTopUpFingerprint(
          paymentMethodCode: 'qpay',
          amount: 100,
          currency: 'ETB',
        ),
        'qpay|100.0|ETB||',
      );
    });
  });

  group('isIdempotencyConflictError', () {
    test('detects idempotency conflict from message', () {
      expect(
        isIdempotencyConflictError(Exception('IDEMPOTENCY_CONFLICT')),
        isTrue,
      );
    });
  });
}
