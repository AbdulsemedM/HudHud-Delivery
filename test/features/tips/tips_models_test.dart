import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/tips/model/tip_add_wallet_result.dart';
import 'package:hudhud_delivery/features/tips/model/tip_calculate_result.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_result.dart';
import 'package:hudhud_delivery/features/tips/model/tip_rate_model.dart';

void main() {
  group('TipRateModel', () {
    test('parses rate and detects custom option', () {
      const json = {
        'id': 6,
        'name': 'Custom',
        'type': 'fixed',
        'value': '0.00',
        'is_default': false,
        'display_order': 6,
        'is_active': true,
      };
      final rate = TipRateModel.fromJson(json);
      expect(rate.id, 6);
      expect(rate.isCustom, isTrue);
    });

    test('parses default no tip option', () {
      const json = {
        'id': 1,
        'name': 'No Tip',
        'type': 'fixed',
        'value': '0.00',
        'is_default': true,
        'display_order': 1,
        'is_active': true,
      };
      final rate = TipRateModel.fromJson(json);
      expect(rate.isDefault, isTrue);
      expect(rate.isNoTip, isTrue);
    });
  });

  group('TipCalculateResult', () {
    test('parses percentage calculate response', () {
      const json = {
        'amount': 298,
        'percentage': 10,
        'tip_option_id': 3,
        'is_custom': false,
      };
      final result = TipCalculateResult.fromJson(json);
      expect(result.amount, 298);
      expect(result.percentage, 10);
      expect(result.tipOptionId, 3);
      expect(result.isCustom, isFalse);
    });

    test('parses custom calculate response', () {
      const json = {
        'amount': 10,
        'percentage': 0.34,
        'tip_option_id': 6,
        'is_custom': true,
      };
      final result = TipCalculateResult.fromJson(json);
      expect(result.amount, 10);
      expect(result.isCustom, isTrue);
    });
  });

  group('TipAddWalletResult', () {
    test('parses wallet add response', () {
      const json = {
        'id': 3,
        'order_id': 2,
        'amount': '5.00',
        'driver_amount': '5.00',
        'vendor_amount': '0.00',
        'recipient_type': 'driver',
        'payment_method': 'wallet',
        'payment_status': 'completed',
        'message': 'Great job!',
        'is_anonymous': true,
        'paid_at': '2026-05-28T08:49:18.000000Z',
      };
      final result = TipAddWalletResult.fromJson(json);
      expect(result.id, 3);
      expect(result.orderId, 2);
      expect(result.paymentStatus, 'completed');
      expect(result.isAnonymous, isTrue);
    });
  });

  group('TipHistoryResult', () {
    test('parses history page with stats', () {
      const json = {
        'success': true,
        'data': {
          'current_page': 1,
          'last_page': 1,
          'total': 1,
          'data': [
            {
              'id': 3,
              'order_id': '2',
              'amount': '5.00',
              'recipient_type': 'driver',
              'payment_method': 'wallet',
              'payment_status': 'completed',
              'order': {
                'id': 2,
                'order_number': 'ORD-001',
                'total_amount': '2980.00',
                'status': 'delivered',
              },
            },
          ],
        },
        'stats': {
          'total_tips_given': 1,
          'total_amount_tipped': 5,
          'average_tip': 5,
        },
      };

      final result = TipHistoryResult.fromResponseData(json);
      expect(result.items.length, 1);
      expect(result.items.first.order?.orderNumber, 'ORD-001');
      expect(result.stats.totalTipsGiven, 1);
      expect(result.stats.totalAmountTipped, 5);
      expect(result.hasMore, isFalse);
    });
  });
}
