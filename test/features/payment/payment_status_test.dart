import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/payment/model/payment_status_result.dart';

void main() {
  group('PaymentStatusResult', () {
    test('parses documented status response', () {
      const json = {
        'success': true,
        'data': {
          'payment': {
            'id': 456,
            'status': 'completed',
            'method': 'waafi',
            'type': 'order',
            'amount': 1500.00,
            'currency': 'KES',
            'transaction_id': 'TXN_abc123',
            'reference': 'ws_CO_01012024123456',
            'paid_at': '2024-01-15T10:30:00.000000Z',
          },
          'related': {
            'order_id': 123,
            'order_status': 'paid',
          },
        },
      };

      final result = PaymentStatusResult.fromJson(json);
      expect(result.isSuccess, isTrue);
      expect(result.paymentId, 456);
      expect(result.status, 'completed');
      expect(result.method, 'waafi');
      expect(result.transactionId, 'TXN_abc123');
      expect(result.reference, 'ws_CO_01012024123456');
      expect(result.relatedOrderId, 123);
      expect(result.relatedOrderStatus, 'paid');
      expect(result.isTerminal, isTrue);
      expect(result.isCompleted, isTrue);
    });

    test('parses pending status as non-terminal', () {
      const json = {
        'success': true,
        'data': {
          'payment': {
            'id': 1,
            'status': 'pending',
            'method': 'sahay',
          },
        },
      };

      final result = PaymentStatusResult.fromJson(json);
      expect(result.isTerminal, isFalse);
      expect(isPendingPaymentStatus(result.status), isTrue);
    });

    test('parses failure envelope', () {
      const json = {
        'success': false,
        'message': 'Payment not found',
      };

      final result = PaymentStatusResult.fromJson(json);
      expect(result.isSuccess, isFalse);
      expect(result.message, 'Payment not found');
    });
  });

  group('payment status helpers', () {
    test('terminal statuses', () {
      expect(isTerminalPaymentStatus('completed'), isTrue);
      expect(isTerminalPaymentStatus('failed'), isTrue);
      expect(isTerminalPaymentStatus('cancelled'), isTrue);
      expect(isTerminalPaymentStatus('refunded'), isTrue);
      expect(isTerminalPaymentStatus('partially_refunded'), isTrue);
      expect(isTerminalPaymentStatus('pending'), isFalse);
      expect(isTerminalPaymentStatus('processing'), isFalse);
    });

    test('shouldPollPaymentStatus for pending flows', () {
      expect(
        shouldPollPaymentStatus(
          isSuccess: true,
          nextAction: 'show_qr_code',
          status: 'pending',
          method: 'waafi',
        ),
        isTrue,
      );
      expect(
        shouldPollPaymentStatus(
          isSuccess: true,
          nextAction: 'user_action_required',
          status: 'pending',
          method: 'edahab',
        ),
        isTrue,
      );
      expect(
        shouldPollPaymentStatus(
          isSuccess: true,
          nextAction: 'redirect_to_hpp',
          status: 'pending',
          method: 'waafi',
        ),
        isTrue,
      );
      expect(
        shouldPollPaymentStatus(
          isSuccess: true,
          nextAction: null,
          status: 'completed',
          method: 'wallet',
        ),
        isFalse,
      );
      expect(
        shouldPollPaymentStatus(
          isSuccess: true,
          nextAction: null,
          status: 'pending',
          method: 'cash_on_delivery',
        ),
        isFalse,
      );
    });
  });
}
