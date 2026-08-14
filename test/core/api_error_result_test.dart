import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/utils/api_error_message.dart';
import 'package:hudhud_delivery/core/utils/api_error_result.dart';

void main() {
  group('parseApiErrorResult', () {
    test('parses validation errors map', () {
      final result = parseApiErrorResult({
        'success': false,
        'message': 'The given data was invalid.',
        'errors': {
          'payment_method_code': [
            'This payment method is currently unavailable.',
          ],
          'amount': ['The amount must be at least 0.01.'],
        },
      }, statusCode: 422);

      expect(result.code, 'validation_error');
      expect(result.message, 'The given data was invalid.');
      expect(result.fieldErrors['payment_method_code'], isNotEmpty);
      expect(result.displayMessage, contains('The given data was invalid.'));
      expect(
        extractApiErrorMessage({
          'success': false,
          'message': 'The given data was invalid.',
          'errors': {
            'payment_method_code': [
              'This payment method is currently unavailable.',
            ],
          },
        }, statusCode: 422),
        result.displayMessage,
      );
    });

    test('uses field messages when top-level message missing', () {
      final result = parseApiErrorResult({
        'success': false,
        'errors': {
          'amount': ['The amount must be at least 0.01.'],
        },
      }, statusCode: 422);

      expect(result.message, 'The amount must be at least 0.01.');
      expect(result.code, 'validation_error');
    });

    test('parses insufficient balance with balance and required', () {
      final result = parseApiErrorResult({
        'success': false,
        'message': 'Insufficient wallet balance.',
        'data': {
          'balance': 100.00,
          'required': 1500.00,
        },
      }, statusCode: 400);

      expect(result.code, 'insufficient_balance');
      expect(result.balance, 100);
      expect(result.requiredAmount, 1500);
      expect(result.displayMessage, contains('Insufficient wallet balance.'));
      expect(result.displayMessage, contains('Balance: 100'));
      expect(result.displayMessage, contains('Required: 1500'));
      expect(
        extractApiErrorMessage({
          'success': false,
          'message': 'Insufficient wallet balance.',
          'data': {'balance': 100.00, 'required': 1500.00},
        }, statusCode: 400),
        result.displayMessage,
      );
    });

    test('parses insufficient balance with deficit at root', () {
      final result = parseApiErrorResult({
        'success': false,
        'message': 'Insufficient wallet balance',
        'balance': 0,
        'required': 48.67,
        'deficit': 48.67,
      }, statusCode: 400);

      expect(result.code, 'insufficient_balance');
      expect(result.balance, 0);
      expect(result.requiredAmount, 48.67);
      expect(result.deficit, 48.67);
      expect(result.isInsufficientBalance, isTrue);
      expect(result.displayMessage, contains('Insufficient wallet balance'));
      expect(result.displayMessage, contains('Short by: 48.67'));
    });

    test('passthrough invalid phone message', () {
      final result = parseApiErrorResult({
        'success': false,
        'message': 'Invalid phone number format. Use format: 254XXXXXXXXX',
      }, statusCode: 422);

      expect(result.code, 'invalid_phone');
      expect(
        result.displayMessage,
        'Invalid phone number format. Use format: 254XXXXXXXXX',
      );
    });

    test('parses payment gateway error', () {
      final result = parseApiErrorResult({
        'success': false,
        'message': 'Payment gateway returned an error',
        'data': {
          'gateway_error': 'Transaction declined by bank',
          'error_code': 'DECLINED',
        },
      }, statusCode: 400);

      expect(result.code, 'payment_failed');
      expect(result.gatewayError, 'Transaction declined by bank');
      expect(result.gatewayErrorCode, 'DECLINED');
      expect(result.displayMessage, contains('Payment gateway returned an error'));
      expect(result.displayMessage, contains('Transaction declined by bank'));
      expect(result.displayMessage, contains('DECLINED'));
    });

    test('maps not-found messages', () {
      final order = parseApiErrorResult({
        'success': false,
        'message': 'Order not found',
        'error': 'order_not_found',
      }, statusCode: 404);
      expect(order.code, 'order_not_found');
      expect(order.displayMessage, 'Order not found');

      final ride = parseApiErrorResult({
        'success': false,
        'message': 'Ride not found',
      }, statusCode: 404);
      expect(ride.code, 'ride_not_found');
    });
  });

  group('userFacingApiError', () {
    test('prefers ApiException.message', () {
      expect(
        userFacingApiError(
          ApiException('Insufficient wallet balance.', statusCode: 400),
        ),
        'Insufficient wallet balance.',
      );
    });

    test('strips Exception prefixes', () {
      expect(
        userFacingApiError(Exception('Invalid phone number format')),
        'Invalid phone number format',
      );
      expect(
        userFacingApiError(
          Exception('Failed to initiate payment: ApiException: Declined (Status: 400)'),
        ),
        'Declined',
      );
    });
  });
}
