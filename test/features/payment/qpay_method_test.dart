import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/utils/qpay_method.dart';

void main() {
  group('qpay_method helpers', () {
    test('isQpay matches code case-insensitively', () {
      expect(isQpay('qpay'), isTrue);
      expect(isQpay('QPay'), isTrue);
      expect(isQpay('waafi'), isFalse);
    });

    test('canInitiateQpay requires enabled usable method', () {
      expect(
        canInitiateQpay({
          'id': 'qpay',
          'enabled': true,
          'can_use': true,
        }),
        isTrue,
      );
      expect(
        canInitiateQpay({
          'id': 'qpay',
          'enabled': true,
          'can_use': false,
        }),
        isFalse,
      );
      expect(
        canInitiateQpay({
          'id': 'qpay',
          'enabled': true,
          'availability_code': 'QPAY_NOT_CONFIGURED',
        }),
        isFalse,
      );
    });

    test('qpayInitiateLooksValid checks qr response', () {
      final valid = PaymentInitiateResult(
        isSuccess: true,
        uiMode: PaymentInitiateUiMode.qrCode,
        paymentId: 99,
        nextAction: 'show_qr_code',
        qrCodeBase64: 'abc',
      );
      expect(qpayInitiateLooksValid(valid), isTrue);

      final missingQr = PaymentInitiateResult(
        isSuccess: true,
        uiMode: PaymentInitiateUiMode.qrCode,
        paymentId: 99,
        nextAction: 'show_qr_code',
      );
      expect(qpayInitiateLooksValid(missingQr), isFalse);
    });
  });
}
