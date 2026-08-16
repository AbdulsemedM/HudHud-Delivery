import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';

void main() {
  group('WalletMutationResponse.fromApi', () {
    test('retains full data envelope for eBirr USSD topup', () {
      final response = WalletMutationResponse.fromApi(
        {
          'success': true,
          'message':
              'eBirr USSD request accepted. Please check your phone to approve the payment.',
          'data': {
            'next_action': 'poll_status',
            'ussd_dispatched': true,
            'instant_credit': false,
            'payment': {
              'status': 'pending',
            },
          },
        },
        fallbackError: 'Failed to top up',
      );

      expect(response.success, isTrue);
      expect(response.payment?['status'], 'pending');
      expect(response.rawData?['next_action'], 'poll_status');
      expect(response.rawData?['ussd_dispatched'], isTrue);
      expect(response.rawData?['instant_credit'], isFalse);

      final result =
          PaymentInitiateResult.fromJson(response.toInitiateEnvelope());
      expect(result.isSuccess, isTrue);
      expect(result.uiMode, PaymentInitiateUiMode.ussdPending);
      expect(result.ussdDispatched, isTrue);
      expect(result.instantCredit, isFalse);
      expect(result.showUssdSuccessCopy, isTrue);
      expect(result.status, 'pending');
    });

    test('toInitiateEnvelope falls back to payment-only data', () {
      const response = WalletMutationResponse(
        success: true,
        message: 'ok',
        payment: {'id': 1, 'status': 'completed', 'method': 'wallet'},
      );

      final envelope = response.toInitiateEnvelope();
      expect(envelope['success'], isTrue);
      expect(envelope['data']['payment']['id'], 1);

      final result = PaymentInitiateResult.fromJson(envelope);
      expect(result.isSuccess, isTrue);
      expect(result.status, 'completed');
      expect(result.method, 'wallet');
    });
  });
}
