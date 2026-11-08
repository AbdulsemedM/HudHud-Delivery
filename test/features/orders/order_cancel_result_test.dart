import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/orders/data/models/order_cancel_result.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_transaction_model.dart';

void main() {
  group('OrderCancelResult', () {
    test('wallet refund (refunded_to_wallet)', () {
      final r = OrderCancelResult.fromResponseBody({
        'message': 'Order cancelled successfully',
        'refund': {
          'status': 'refunded_to_wallet',
          'amount': 1005,
          'currency': 'etb',
        },
      });
      expect(r.refund, isNotNull);
      expect(r.refund!.isToWallet, isTrue);
      expect(r.refund!.formattedAmount, 'ETB 1,005');
    });

    test('wallet payment refund (refunded) with decimals', () {
      final refund = OrderRefund.tryParse({
        'status': 'refunded',
        'amount': '12.5',
        'currency': 'USD',
      });
      expect(refund!.isToWallet, isTrue);
      expect(refund.formattedAmount, r'$12.50');
    });

    test('manual and not required', () {
      expect(
        OrderRefund.tryParse({'status': 'manual_refund_required'})!.isManual,
        isTrue,
      );
      final none = OrderRefund.tryParse({'status': 'not_required'})!;
      expect(none.isToWallet, isFalse);
      expect(none.isManual, isFalse);
    });

    test('customer cancel body without refund (current OrderController)', () {
      final r = OrderCancelResult.fromResponseBody({
        'message': 'Order cancelled successfully',
      });
      expect(r.refund, isNull);
      expect(r.message, 'Order cancelled successfully');
      expect(OrderCancelResult.fromResponseBody(null).refund, isNull);
      expect(OrderRefund.tryParse('refunded'), isNull);
    });
  });

  group('Wallet refund transactions', () {
    WalletTransactionModel tx(String type, String description) =>
        WalletTransactionModel.fromJson({
          'id': 1,
          'type': type,
          'amount': '1005.00',
          'description': description,
        });

    test('backend refund descriptions are refunds', () {
      expect(tx('credit', 'Order cancellation refund #HD-1001').isRefund, isTrue);
      expect(
        tx('credit', 'Order cancellation refund #1001 (EBIRR)').isRefund,
        isTrue,
      );
      expect(
        tx('credit', 'Refund: order #1001 was cancelled before payment completed')
            .isRefund,
        isTrue,
      );
      expect(tx('credit', 'Finance refund for order #1001').isRefund, isTrue);
    });

    test('other credits and debits are not refunds', () {
      expect(tx('credit', 'Wallet top-up').isRefund, isFalse);
      expect(tx('debit', 'Order cancellation refund #1').isRefund, isFalse);
      expect(tx('debit', 'Payment for order #1').isRefund, isFalse);
    });
  });
}
