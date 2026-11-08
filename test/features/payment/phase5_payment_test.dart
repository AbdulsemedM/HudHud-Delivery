import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/model/payment_status_result.dart';
import 'package:hudhud_delivery/features/payment/utils/order_payment_issue.dart';

void main() {
  group('Cash on delivery (next_action pay_cash_on_delivery)', () {
    // PaymentController::processPayment COD answer: 201, payment pending.
    const json = {
      'success': true,
      'message': 'Pay in cash on delivery.',
      'data': {
        'payment': {
          'id': 9,
          'status': 'pending',
          'method': 'cash_on_delivery',
          'amount': 1005.0,
          'currency': 'ETB',
        },
        'redirect_url': null,
        'next_action': 'pay_cash_on_delivery',
      },
    };

    test('is success, COD, not polled and not "completed"', () {
      final result = PaymentInitiateResult.fromJson(json);
      expect(result.isSuccess, isTrue);
      expect(result.uiMode, PaymentInitiateUiMode.success);
      expect(result.isCashOnDelivery, isTrue);
      expect(result.status, 'pending');
      expect(
        shouldPollPaymentStatus(
          isSuccess: true,
          nextAction: result.nextAction,
          status: result.status,
          method: result.method,
        ),
        isFalse,
      );
    });

    test('next_action alone marks COD even without method', () {
      final result = PaymentInitiateResult.fromJson({
        'success': true,
        'data': {
          'payment': {'id': 9, 'status': 'pending'},
          'next_action': 'pay_cash_on_delivery',
        },
      });
      expect(result.isCashOnDelivery, isTrue);
      expect(
        shouldPollPaymentStatus(
          isSuccess: true,
          nextAction: result.nextAction,
          status: result.status,
          method: result.method,
        ),
        isFalse,
      );
    });
  });

  group('classifyOrderPaymentIssue', () {
    test('409 in progress', () {
      expect(
        classifyOrderPaymentError(ApiException(
          'A payment for this order is already in progress. Approve or decline it on your phone, then try again in a few minutes.',
          statusCode: 409,
          data: {
            'success': false,
            'message':
                'A payment for this order is already in progress. Approve or decline it on your phone, then try again in a few minutes.',
          },
        )),
        OrderPaymentIssue.inProgress,
      );
    });

    test('409 already paid', () {
      expect(
        classifyOrderPaymentError(ApiException(
          'This order has already been paid.',
          statusCode: 409,
          data: {'success': false, 'message': 'This order has already been paid.'},
        )),
        OrderPaymentIssue.alreadyPaid,
      );
    });

    test('422 currency and amount mismatch → totals changed', () {
      expect(
        classifyOrderPaymentError(ApiException(
          'Payment currency must match the order currency.',
          statusCode: 422,
          data: {
            'success': false,
            'message': 'Payment currency must match the order currency.',
            'expected_currency': 'USD',
            'provided_currency': 'ETB',
          },
        )),
        OrderPaymentIssue.totalsChanged,
      );
      expect(
        classifyOrderPaymentError(ApiException(
          'Payment amount does not match the order total.\nExpected: 1005 · Provided: 1000',
          statusCode: 422,
          data: {
            'success': false,
            'message': 'Payment amount does not match the order total.',
            'expected_amount': 1005,
            'provided_amount': 1000,
          },
        )),
        OrderPaymentIssue.totalsChanged,
      );
    });

    test('422 not payable (delivered / cancelled)', () {
      expect(
        classifyOrderPaymentError(ApiException(
          'This order cannot be paid for.',
          statusCode: 422,
          data: {
            'message': 'This order cannot be paid for.',
            'errors': {
              'order': ['This order cannot be paid for.'],
            },
          },
        )),
        OrderPaymentIssue.notPayable,
      );
    });

    test('anything else is not classified', () {
      expect(
        classifyOrderPaymentError(ApiException('Timeout', statusCode: 504)),
        isNull,
      );
      expect(
        classifyOrderPaymentError(ApiException(
          'Insufficient balance',
          statusCode: 422,
          data: {'message': 'Insufficient balance'},
        )),
        isNull,
      );
      expect(classifyOrderPaymentError(Exception('x')), isNull);
    });
  });
}
