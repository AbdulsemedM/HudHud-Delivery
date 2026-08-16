import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/data/models/create_delivery_result.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_payment_helper.dart';

void main() {
  group('resolveServerDeliveryPaymentAmount', () {
    test('returns persisted total only', () {
      expect(
        resolveServerDeliveryPaymentAmount(
          const CreateDeliveryResult(deliveryId: 1, totalAmount: 95),
        ),
        95,
      );
    });

    test('rejects missing or non-positive totals', () {
      expect(
        resolveServerDeliveryPaymentAmount(
          const CreateDeliveryResult(deliveryId: 1),
        ),
        isNull,
      );
      expect(
        resolveServerDeliveryPaymentAmount(
          const CreateDeliveryResult(deliveryId: 1, totalAmount: 0),
        ),
        isNull,
      );
      expect(
        resolveServerDeliveryPaymentAmount(
          const CreateDeliveryResult(deliveryId: 1, totalAmount: -5),
        ),
        isNull,
      );
    });
  });

  group('formatPaymentMethodLabel', () {
    test('maps known API codes to display names', () {
      expect(formatPaymentMethodLabel('wallet'), 'Wallet');
      expect(formatPaymentMethodLabel('ebirr_coop'), 'eBirr (Coop)');
      expect(formatPaymentMethodLabel('cash_on_delivery'), 'Cash on Delivery');
    });

    test('humanizes unknown codes', () {
      expect(formatPaymentMethodLabel('some_new_method'), 'Some New Method');
    });

    test('returns dash for empty input', () {
      expect(formatPaymentMethodLabel(null), '—');
      expect(formatPaymentMethodLabel(''), '—');
    });
  });

  group('canRetryDeliveryPayment', () {
    test('hides for paid, COD, and cancelled deliveries', () {
      expect(
        canRetryDeliveryPayment(
          paymentStatus: 'paid',
          paymentMethod: 'ebirr_coop',
        ),
        isFalse,
      );
      expect(
        canRetryDeliveryPayment(
          paymentStatus: 'pending',
          paymentMethod: 'cash_on_delivery',
        ),
        isFalse,
      );
      expect(
        canRetryDeliveryPayment(
          paymentStatus: 'failed',
          paymentMethod: 'ebirr_coop',
          deliveryStatus: 'cancelled',
        ),
        isFalse,
      );
    });

    test('shows for unpaid wallet and failed mobile money', () {
      expect(
        canRetryDeliveryPayment(
          paymentStatus: 'pending',
          paymentMethod: 'wallet',
        ),
        isTrue,
      );
      expect(
        canRetryDeliveryPayment(
          paymentStatus: 'failed',
          paymentMethod: 'ebirr_coop',
        ),
        isTrue,
      );
      expect(
        canRetryDeliveryPayment(
          paymentStatus: null,
          paymentMethod: 'sahay',
        ),
        isTrue,
      );
    });
  });

  group('retryPaymentPhone', () {
    test('sends 2519xxxxxxxx for eBirr and Sahay', () {
      expect(
        retryPaymentPhone(
          paymentMethod: 'ebirr_coop',
          paymentPhone: '0911679409',
        ),
        '251911679409',
      );
      expect(
        retryPaymentPhone(
          paymentMethod: 'sahay',
          paymentPhone: '251911679409',
        ),
        '251911679409',
      );
    });

    test('falls back to sender phone and omits wallet', () {
      expect(
        retryPaymentPhone(
          paymentMethod: 'ebirr_kaafi',
          senderPhone: '251915741199',
        ),
        '251915741199',
      );
      expect(
        retryPaymentPhone(paymentMethod: 'wallet', paymentPhone: '0911679409'),
        '',
      );
    });
  });
}
