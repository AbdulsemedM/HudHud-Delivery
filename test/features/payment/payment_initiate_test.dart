import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';

void main() {
  group('PaymentInitiateResult', () {
    test('parses Sahay success with poll_status', () {
      const json = {
        'success': true,
        'message': 'Sahay payment initiated. Please complete the payment.',
        'data': {
          'payment': {
            'id': 19,
            'status': 'pending',
            'amount': '5.00',
            'currency': 'ETB',
            'transaction_id': '4bf38782-3db5-4210-9d2b-99645f81fd09',
            'phone_number': '251911679409',
            'payment_details': {
              'phone': '251911679409',
              'sahay_reference_number': 'REF_19_1778938841',
            },
          },
          'next_action': 'poll_status',
        },
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.isSuccess, isTrue);
      expect(result.uiMode, PaymentInitiateUiMode.ussdPending);
      expect(result.nextAction, 'poll_status');
      expect(result.referenceNumber, 'REF_19_1778938841');
      expect(result.phone, '251911679409');
    });

    test('parses QPay success with show_qr_code', () {
      const json = {
        'success': true,
        'message': 'QPay payment initiated. Please scan the QR code to complete payment.',
        'data': {
          'payment': {
            'id': 27,
            'status': 'pending',
            'amount': '100.00',
            'currency': 'ETB',
            'transaction_id': 'qr-payload-id',
            'payment_details': {
              'qpay_qr_code': 'aVZORw0KGgo=',
              'qpay_qr_id': '000201010211',
              'qpay_awb': 'ORD__1778942296',
            },
          },
          'next_action': 'show_qr_code',
        },
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.isSuccess, isTrue);
      expect(result.uiMode, PaymentInitiateUiMode.qrCode);
      expect(result.qrCodeBase64, 'aVZORw0KGgo=');
      expect(result.qrPayload, '000201010211');
    });

    test('treats Ebirr RCS_SUCCESS in errors as success', () {
      const json = {
        'message': 'RCS_SUCCESS',
        'errors': {
          'payment': ['RCS_SUCCESS'],
        },
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.isSuccess, isTrue);
      expect(result.uiMode, PaymentInitiateUiMode.success);
      expect(result.message, 'RCS_SUCCESS');
      expect(PaymentInitiateResult.isEbirrRcsSuccess(json), isTrue);
    });

    test('uiModeFromNextAction maps known actions', () {
      expect(
        PaymentInitiateResult.uiModeFromNextAction('poll_status'),
        PaymentInitiateUiMode.ussdPending,
      );
      expect(
        PaymentInitiateResult.uiModeFromNextAction('show_qr_code'),
        PaymentInitiateUiMode.qrCode,
      );
      expect(
        PaymentInitiateResult.uiModeFromNextAction(null),
        PaymentInitiateUiMode.success,
      );
    });

    test('parses failure response', () {
      const json = {
        'success': false,
        'message': 'Insufficient balance',
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.isSuccess, isFalse);
      expect(result.uiMode, PaymentInitiateUiMode.failure);
      expect(result.message, 'Insufficient balance');
    });
  });

  group('payment method helpers', () {
    test('skips initiate for wallet and cash_on_delivery', () {
      expect(paymentMethodSkipsInitiate('wallet'), isTrue);
      expect(paymentMethodSkipsInitiate('cash_on_delivery'), isTrue);
      expect(paymentMethodSkipsInitiate('sahay'), isFalse);
    });

    test('needs details form for mobile money methods', () {
      expect(paymentMethodNeedsDetailsForm('sahay'), isTrue);
      expect(paymentMethodNeedsDetailsForm('ebirr'), isTrue);
      expect(paymentMethodNeedsDetailsForm('qpay'), isFalse);
    });
  });
}
