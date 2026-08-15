import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';

void main() {
  group('PaymentInitiateResult', () {
    test('parses wallet instant completed response', () {
      const json = {
        'success': true,
        'message': 'Payment completed successfully',
        'data': {
          'payment': {
            'id': 456,
            'status': 'completed',
            'method': 'wallet',
            'type': 'order',
            'amount': 1500.00,
            'currency': 'KES',
            'transaction_id': 'TXN_abc123',
          },
          'next_action': null,
          'redirect_url': null,
          'qr_code': null,
          'customer_message': null,
        },
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.isSuccess, isTrue);
      expect(result.uiMode, PaymentInitiateUiMode.success);
      expect(result.status, 'completed');
      expect(result.method, 'wallet');
      expect(result.transactionId, 'TXN_abc123');
      expect(result.nextAction, isNull);
    });

    test('parses cash on delivery response', () {
      const json = {
        'success': true,
        'message': 'Order confirmed. Pay on delivery.',
        'data': {
          'payment': {
            'id': 456,
            'status': 'pending',
            'method': 'cash_on_delivery',
            'type': 'order',
            'amount': 1500.00,
            'currency': 'KES',
          },
          'next_action': null,
          'order_status': 'confirmed',
          'customer_message': 'Pay KES 1,500.00 upon delivery.',
        },
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.isSuccess, isTrue);
      expect(result.uiMode, PaymentInitiateUiMode.success);
      expect(result.method, 'cash_on_delivery');
      expect(result.orderStatus, 'confirmed');
      expect(result.customerMessage, 'Pay KES 1,500.00 upon delivery.');
      expect(result.idempotentReplay, isFalse);
    });

    test('parses idempotent_replay as successful initiate', () {
      const json = {
        'success': true,
        'idempotent_replay': true,
        'message': 'Payment already initiated',
        'data': {
          'payment': {
            'id': 789,
            'status': 'pending',
            'method': 'ebirr_coop',
            'amount': 95.00,
            'currency': 'ETB',
          },
          'next_action': 'user_action_required',
          'customer_message': 'Approve the payment on your phone.',
        },
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.isSuccess, isTrue);
      expect(result.idempotentReplay, isTrue);
      expect(result.paymentId, 789);
      expect(result.uiMode, PaymentInitiateUiMode.userActionRequired);
    });

    test('parses top-level qr_code for show_qr_code', () {
      const json = {
        'success': true,
        'message': 'Payment initiated successfully',
        'data': {
          'payment': {
            'id': 456,
            'status': 'pending',
            'method': 'waafi',
            'amount': 1500.00,
            'currency': 'KES',
            'reference': 'ABC123456',
          },
          'next_action': 'show_qr_code',
          'qr_code': 'data:image/png;base64,aVZORw0KGgo=',
          'qr_id': 'QR_abc123',
          'customer_message': 'Please check your phone to complete the payment.',
          'expires_at': '2024-01-15T10:35:00.000000Z',
        },
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.isSuccess, isTrue);
      expect(result.uiMode, PaymentInitiateUiMode.qrCode);
      expect(result.qrCodeBase64, 'aVZORw0KGgo=');
      expect(result.qrId, 'QR_abc123');
      expect(result.expiresAt, '2024-01-15T10:35:00.000000Z');
      expect(result.referenceNumber, 'ABC123456');
    });

    test('parses nested QPay qr fallback', () {
      const json = {
        'success': true,
        'message': 'QPay payment initiated.',
        'data': {
          'payment': {
            'id': 27,
            'status': 'pending',
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
      expect(result.uiMode, PaymentInitiateUiMode.qrCode);
      expect(result.qrCodeBase64, 'aVZORw0KGgo=');
      expect(result.qrPayload, '000201010211');
    });

    test('parses redirect_to_hpp', () {
      const json = {
        'success': true,
        'message': 'Waafi payment initiated',
        'data': {
          'payment': {
            'id': 456,
            'status': 'pending',
            'method': 'waafi',
            'amount': 1500.00,
            'currency': 'KES',
          },
          'next_action': 'redirect_to_hpp',
          'redirect_url': 'https://waafipay.com/pay/ABC123456',
          'customer_message': 'Complete payment on the hosted page.',
        },
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.uiMode, PaymentInitiateUiMode.redirectToHpp);
      expect(result.redirectUrl, 'https://waafipay.com/pay/ABC123456');
    });

    test('parses user_action_required', () {
      const json = {
        'success': true,
        'message': 'STK push sent to your phone',
        'data': {
          'payment': {
            'id': 456,
            'status': 'pending',
            'method': 'edahab',
            'reference': 'ABC123456',
          },
          'next_action': 'user_action_required',
          'customer_message':
              'Please check your phone and enter your PIN to complete the payment.',
        },
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.uiMode, PaymentInitiateUiMode.userActionRequired);
      expect(result.referenceNumber, 'ABC123456');
    });

    test('maps legacy poll_status to ussdPending', () {
      const json = {
        'success': true,
        'message': 'Sahay payment initiated.',
        'data': {
          'payment': {
            'id': 19,
            'status': 'pending',
            'payment_details': {
              'sahay_reference_number': 'REF_19',
            },
          },
          'next_action': 'poll_status',
        },
      };

      final result = PaymentInitiateResult.fromJson(json);
      expect(result.uiMode, PaymentInitiateUiMode.ussdPending);
      expect(result.referenceNumber, 'REF_19');
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
      expect(PaymentInitiateResult.isEbirrRcsSuccess(json), isTrue);
    });

    test('uiModeFromNextAction maps known actions', () {
      expect(
        PaymentInitiateResult.uiModeFromNextAction('show_qr_code'),
        PaymentInitiateUiMode.qrCode,
      );
      expect(
        PaymentInitiateResult.uiModeFromNextAction('redirect_to_hpp'),
        PaymentInitiateUiMode.redirectToHpp,
      );
      expect(
        PaymentInitiateResult.uiModeFromNextAction('user_action_required'),
        PaymentInitiateUiMode.userActionRequired,
      );
      expect(
        PaymentInitiateResult.uiModeFromNextAction('poll_status'),
        PaymentInitiateUiMode.ussdPending,
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
    test('never skips initiate', () {
      expect(paymentMethodSkipsInitiate('wallet'), isFalse);
      expect(paymentMethodSkipsInitiate('cash_on_delivery'), isFalse);
      expect(paymentMethodSkipsInitiate('sahay'), isFalse);
    });

    test('needs details form for mobile money methods', () {
      expect(paymentMethodNeedsDetailsForm('sahay'), isTrue);
      expect(paymentMethodNeedsDetailsForm('ebirr'), isTrue);
      expect(paymentMethodNeedsDetailsForm('ebirr_kaafi'), isTrue);
      expect(paymentMethodNeedsDetailsForm('ebirr_coop'), isTrue);
      expect(paymentMethodNeedsDetailsForm('waafi'), isTrue);
      expect(paymentMethodNeedsDetailsForm('edahab'), isTrue);
      expect(paymentMethodNeedsDetailsForm('wallet'), isFalse);
    });

    test('filters allowed payment method codes', () {
      final filtered = filterAllowedPaymentMethods([
        {'id': 'wallet', 'enabled': true},
        {'id': 'telebirr', 'enabled': true},
        {'id': 'qpay', 'enabled': true},
        {'id': 'ebirr_kaafi', 'enabled': true},
        {'id': 'ebirr_coop', 'enabled': true},
      ]);
      expect(filtered.map((m) => m['id']), ['wallet', 'ebirr_kaafi', 'ebirr_coop']);
    });

    test('isEbirrPaymentMethodCode recognizes ebirr variants', () {
      expect(isEbirrPaymentMethodCode('ebirr'), isTrue);
      expect(isEbirrPaymentMethodCode('ebirr_kaafi'), isTrue);
      expect(isEbirrPaymentMethodCode('ebirr_coop'), isTrue);
      expect(isEbirrPaymentMethodCode('waafi'), isFalse);
    });
  });

  group('payment phone + details builder', () {
    test('normalizes phones per method', () {
      expect(normalizePaymentPhone('0712345678', 'waafi'), '254712345678');
      expect(normalizePaymentPhone('0911679409', 'sahay'), '251911679409');
      expect(normalizePaymentPhone('251915741199', 'ebirr_kaafi'), '251915741199');
      expect(normalizePaymentPhone('656013956', 'edahab'), '656013956');
    });

    test('validates phones per method', () {
      expect(validatePaymentPhone('254712345678', 'waafi'), isNull);
      expect(validatePaymentPhone('12345', 'waafi'), isNotNull);
      expect(validatePaymentPhone('251911679409', 'sahay'), isNull);
      expect(validatePaymentPhone('811234567', 'ebirr_coop'), isNotNull);
    });

    test('buildInitiatePaymentDetails includes use_hpp and provider', () {
      final waafi = buildInitiatePaymentDetails(
        paymentMethodCode: 'waafi',
        collectedDetails: {'phone': '254712345678', 'use_hpp': true},
        orderId: 1,
      );
      expect(waafi['phone'], '254712345678');
      expect(waafi['use_hpp'], isTrue);

      final ebirr = buildInitiatePaymentDetails(
        paymentMethodCode: 'ebirr',
        collectedDetails: {'phone': '251915741199', 'provider': 'coop'},
        orderId: 1,
      );
      expect(ebirr['provider'], 'coop');
      expect(ebirr['phone'], '251915741199');
      expect(ebirr.containsKey('use_hpp'), isFalse);
    });
  });
}
