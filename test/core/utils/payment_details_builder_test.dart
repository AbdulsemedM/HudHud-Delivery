import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/payment_details_builder.dart';

void main() {
  test('buildWalletTopUpPaymentDetails uses qr channel for qpay', () {
    expect(
      buildWalletTopUpPaymentDetails(paymentMethodCode: 'qpay'),
      {'channel': 'qr'},
    );
  });
}
