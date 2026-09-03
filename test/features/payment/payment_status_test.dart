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

    test('parses wallet top-up settlement credited', () {
      const json = {
        'success': true,
        'data': {
          'wallet_topup_settlement': 'credited',
          'payment': {
            'id': 12,
            'status': 'pending',
            'method': 'qpay',
          },
        },
      };

      final result = PaymentStatusResult.fromJson(json);
      expect(result.isWalletTopUpSettled, isTrue);
      expect(result.walletTopupSettlement, 'credited');
    });

    test('parses qpay terminal failure', () {
      const json = {
        'success': true,
        'data': {
          'qpay_status': 'EXPIRED',
          'payment': {
            'id': 12,
            'status': 'pending',
            'method': 'qpay',
          },
        },
      };

      final result = PaymentStatusResult.fromJson(json);
      expect(result.isWalletTopUpTerminalFailure, isTrue);
    });

    test('wallet top-up credited settlement is settled', () {
      const json = {
        'success': true,
        'data': {
          'status': 'completed',
          'payment': {'id': 901, 'status': 'completed'},
          'qpay_status': 'COMPLETED',
          'wallet_topup_settlement': 'credited',
        },
      };

      final result = PaymentStatusResult.fromJson(json);
      expect(isWalletTopUpSettled(result), isTrue);
      expect(shouldKeepPollingWalletTopUp(result), isFalse);
    });

    test('awaiting_provider_amount with completed is not settled', () {
      const json = {
        'success': true,
        'data': {
          'status': 'completed',
          'payment': {'id': 901, 'status': 'completed'},
          'wallet_topup_settlement': 'awaiting_provider_amount',
        },
      };

      final result = PaymentStatusResult.fromJson(json);
      expect(isWalletTopUpSettled(result), isFalse);
      expect(shouldKeepPollingWalletTopUp(result), isTrue);
    });

    test('qpay EXPIRED with pending payment is terminal failure', () {
      const json = {
        'success': true,
        'data': {
          'payment': {'id': 901, 'status': 'pending'},
          'qpay_status': 'EXPIRED',
        },
      };

      final result = PaymentStatusResult.fromJson(json);
      expect(isQPayTerminalFailure(result), isTrue);
      expect(shouldKeepPollingWalletTopUp(result), isFalse);
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
