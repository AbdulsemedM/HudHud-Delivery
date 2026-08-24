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

      expect(result.code, 'payment_method_unavailable');
      expect(
        result.message,
        'This payment method is currently unavailable. The amount must be at least 0.01.',
      );
      expect(result.fieldErrors['payment_method_code'], isNotEmpty);
      expect(
        result.displayMessage,
        contains('This payment method is currently unavailable.'),
      );
      expect(
        result.displayMessage,
        contains('The amount must be at least 0.01.'),
      );
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
        'This payment method is currently unavailable.',
      );
    });

    test('surfaces email already taken over generic Validation Error', () {
      final result = parseApiErrorResult({
        'message': 'Validation Error',
        'errors': {
          'email': ['The email has already been taken.'],
        },
      }, statusCode: 422);

      expect(result.code, 'validation_error');
      expect(result.message, 'The email has already been taken.');
      expect(result.displayMessage, 'The email has already been taken.');
      expect(
        extractApiErrorMessage({
          'message': 'Validation Error',
          'errors': {
            'email': ['The email has already been taken.'],
          },
        }, statusCode: 422),
        'The email has already been taken.',
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

    test('parses payment gateway error without leaking provider payload', () {
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
      expect(result.displayMessage, 'Payment gateway returned an error');
      expect(result.displayMessage, isNot(contains('Transaction declined by bank')));
      expect(result.displayMessage, isNot(contains('DECLINED')));
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

    test('parses payment amount mismatch 422', () {
      final result = parseApiErrorResult({
        'success': false,
        'message': 'Payment amount does not match the delivery total.',
        'expected_amount': 95.00,
        'provided_amount': 161.00,
        'currency': 'ETB',
      }, statusCode: 422);

      expect(result.code, 'amount_mismatch');
      expect(result.isAmountMismatch, isTrue);
      expect(result.expectedAmount, 95);
      expect(result.providedAmount, 161);
      expect(result.displayMessage, contains('Payment amount does not match'));
      expect(result.displayMessage, contains('Expected: 95'));
      expect(result.displayMessage, contains('Provided: 161'));
    });

    test('detects amount mismatch from message when fields missing', () {
      final result = parseApiErrorResult({
        'success': false,
        'message': 'Payment amount does not match the delivery total.',
      }, statusCode: 422);

      expect(result.isAmountMismatch, isTrue);
      expect(result.code, 'amount_mismatch');
    });

    test('preserves ROUTE_DISTANCE_* codes on 503', () {
      final result = parseApiErrorResult({
        'success': false,
        'message': 'Unable to resolve delivery route distance.',
        'error': 'ROUTE_DISTANCE_UNAVAILABLE',
      }, statusCode: 503);

      expect(result.code, 'ROUTE_DISTANCE_UNAVAILABLE');
      expect(result.isRouteDistanceError, isTrue);
      expect(result.statusCode, 503);
    });

    test('detects CITY_VEHICLE_NOT_SUPPORTED on 422', () {
      final result = parseApiErrorResult({
        'success': false,
        'code': 'CITY_VEHICLE_NOT_SUPPORTED',
        'message':
            'Addis Ababa does not support motorbike deliveries. Available vehicle types: bajaj, pickup.',
      }, statusCode: 422);

      expect(result.code, 'CITY_VEHICLE_NOT_SUPPORTED');
      expect(result.isCityVehicleNotSupported, isTrue);
      expect(result.statusCode, 422);
      expect(result.displayMessage, contains('does not support'));
    });

    test('detects PICKUP_SERVICE_AREA_UNAVAILABLE on 422', () {
      final result = parseApiErrorResult({
        'success': false,
        'code': 'PICKUP_SERVICE_AREA_UNAVAILABLE',
        'message': 'HudHud does not currently serve the selected pickup city.',
      }, statusCode: 422);

      expect(result.code, 'PICKUP_SERVICE_AREA_UNAVAILABLE');
      expect(result.isPickupServiceAreaUnavailable, isTrue);
      expect(result.isCityVehicleNotSupported, isFalse);
    });

    test('detects scheduled_pickup field validation', () {
      final result = parseApiErrorResult({
        'message': 'The given data was invalid.',
        'errors': {
          'scheduled_pickup': [
            'The scheduled pickup must be a future date and time.',
          ],
        },
      }, statusCode: 422);

      expect(result.isValidation, isTrue);
      expect(result.hasScheduledPickupValidation, isTrue);
      expect(
        result.displayMessage,
        contains('future date and time'),
      );
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
