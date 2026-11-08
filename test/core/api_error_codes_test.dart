import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/l10n/api_error_l10n.dart';
import 'package:hudhud_delivery/core/utils/api_error_result.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  group('pre-launch API error codes', () {
    test('STORE_CLOSED keeps its code and store_status on a 422', () {
      final result = parseApiErrorResult({
        'success': false,
        'code': 'STORE_CLOSED',
        'message': 'This store is closed now. It opens tomorrow at 08:00.',
        'store_status': {
          'state': 'closed',
          'code': 'STORE_CLOSED',
          'accepting_orders': false,
          'opens_at': '2026-11-09T08:00:00+03:00',
          'reason': 'outside_hours',
        },
      }, statusCode: 422);

      expect(result.code, kStoreClosedCode);
      expect(result.isStoreClosed, isTrue);
      expect(result.isStoreUnavailable, isTrue);
      expect(result.isValidation, isFalse);
      expect(result.storeStatus?['state'], 'closed');
    });

    test('STORE_PAUSED is busy', () {
      final result = parseApiErrorResult({
        'code': 'STORE_PAUSED',
        'message': 'This store is busy.',
      }, statusCode: 422);
      expect(result.isStorePaused, isTrue);
      expect(result.isStoreUnavailable, isTrue);
    });

    test('ITEM_SOLD_OUT exposes the product id', () {
      final result = parseApiErrorResult({
        'success': false,
        'code': 'ITEM_SOLD_OUT',
        'message': 'Shiro is sold out today. Remove it to continue.',
        'product_id': 42,
      }, statusCode: 422);
      expect(result.isItemSoldOut, isTrue);
      expect(result.productId, 42);
    });

    test('OUTSTANDING_DUES exposes amount and currency', () {
      final result = parseApiErrorResult({
        'success': false,
        'code': 'OUTSTANDING_DUES',
        'message': 'You have an outstanding balance of ETB 30.00.',
        'amount': 30,
        'currency': 'etb',
        'amounts': [
          {'currency': 'ETB', 'amount': 30},
        ],
      }, statusCode: 422);
      expect(result.isOutstandingDues, isTrue);
      expect(result.amount, 30);
      expect(result.currency, 'ETB');
    });

    test('CITY_* codes and the mismatching market', () {
      final mismatch = parseApiErrorResult({
        'code': 'CITY_MARKET_MISMATCH',
        'message': 'These addresses are in Hargeisa.',
        'market': 'Hargeisa',
        'selected_market': 'addis_ababa',
      }, statusCode: 422);
      expect(mismatch.isCityScopeError, isTrue);
      expect(mismatch.marketCode, 'hargeisa');

      for (final code in [kCityOutsideCode, kCityCrossMarketCode]) {
        final r = parseApiErrorResult({'code': code}, statusCode: 422);
        expect(r.code, code);
        expect(r.isCityScopeError, isTrue);
      }
    });

    test('other stable API codes survive a 422 (FEATURE_DISABLED, parcels)',
        () {
      expect(
        parseApiErrorResult({'code': 'FEATURE_DISABLED'}, statusCode: 422).code,
        'FEATURE_DISABLED',
      );
      expect(
        parseApiErrorResult(
          {'code': 'PARCEL_QUOTE_EXPIRED'},
          statusCode: 422,
        ).code,
        'PARCEL_QUOTE_EXPIRED',
      );
    });

    test('a free-text error no longer hides the real code', () {
      final result = parseApiErrorResult({
        'error': 'SQLSTATE something went wrong',
        'code': 'STORE_PAUSED',
      }, statusCode: 422);
      expect(result.code, kStorePausedCode);
    });

    test('upper-case alias of a known id is folded onto it', () {
      final result = parseApiErrorResult({
        'code': 'INSUFFICIENT_BALANCE',
        'message': 'Not enough money',
      }, statusCode: 400);
      expect(result.code, 'insufficient_balance');
    });

    test('free text and single words are still dropped', () {
      final result = parseApiErrorResult({
        'error': 'Something failed badly',
        'message': 'Oops',
      }, statusCode: 422);
      expect(result.code, 'validation_error');
    });
  });

  group('localized messages', () {
    test('store closed with an opening time', () {
      final opens = DateTime(2026, 11, 9, 8, 30);
      final error = parseApiErrorResult({
        'code': 'STORE_CLOSED',
        'store_status': {
          'state': 'closed',
          'opens_at': opens.toIso8601String(),
        },
      }, statusCode: 422);
      expect(
        localizedKnownApiError(en, error, now: DateTime(2026, 11, 8, 22)),
        'This store is closed right now. Opens tomorrow 08:30.',
      );
    });

    test('busy store without a resume time', () {
      final error =
          parseApiErrorResult({'code': 'STORE_PAUSED'}, statusCode: 422);
      expect(
        localizedKnownApiError(en, error),
        'This store is busy and not taking orders right now.',
      );
    });

    test('sold out names the cart item when known', () {
      final error = parseApiErrorResult(
        {'code': 'ITEM_SOLD_OUT', 'product_id': 7},
        statusCode: 422,
      );
      expect(
        localizedKnownApiError(en, error, itemName: 'Shiro'),
        'Shiro is sold out today. Remove it to continue.',
      );
      expect(
        localizedKnownApiError(en, error),
        'An item in your cart is sold out today. Remove it to continue.',
      );
    });

    test('dues show the amount in its currency (USD uses \$)', () {
      final error = parseApiErrorResult({
        'code': 'OUTSTANDING_DUES',
        'amount': 2.5,
        'currency': 'USD',
      }, statusCode: 422);
      expect(localizedKnownApiError(en, error), contains(r'$2.50'));
    });

    test('city mismatch without a loaded market list stays generic', () {
      final error = parseApiErrorResult(
        {'code': 'CITY_MARKET_MISMATCH', 'market': 'hargeisa'},
        statusCode: 422,
      );
      expect(
        localizedKnownApiError(en, error),
        en.p12ErrCityMismatchGeneric,
      );
    });

    test('unknown codes are left to the caller', () {
      final error = parseApiErrorResult(
        {'code': 'SOMETHING_ELSE', 'message': 'x'},
        statusCode: 422,
      );
      expect(localizedKnownApiError(en, error), isNull);
    });

    test('network, timeout, session and server failures', () {
      expect(
        localizedApiErrorMessage(
          en,
          message: 'Connection error. Please check your internet connection.',
        ),
        en.p12ErrNetwork,
      );
      expect(
        localizedApiErrorMessage(en,
            message: 'Receive timeout. Please try again.'),
        en.p12ErrTimeout,
      );
      expect(
        localizedApiErrorMessage(en, statusCode: 401, message: 'x'),
        en.p12ErrSessionExpired,
      );
      expect(
        localizedApiErrorMessage(en, statusCode: 500, message: 'x'),
        en.p12ErrServer,
      );
      expect(
        localizedApiErrorMessage(en, statusCode: 422, message: 'Pick a size'),
        'Pick a size',
      );
    });

    test('a code passed separately from the body is honoured', () {
      expect(
        localizedApiErrorMessage(en, code: 'STORE_PAUSED', statusCode: 422),
        en.p12ErrStoreBusy,
      );
    });
  });

  test('every locale has the pre-launch strings', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.p12ErrStoreClosed, isNotEmpty);
      expect(l10n.p12ErrOutstandingDues('ETB 5.00'), contains('ETB 5.00'));
      expect(l10n.p12ErrCityMismatch('Hargeisa'), contains('Hargeisa'));
      expect(l10n.p12StoreOpensAt('08:30'), contains('08:30'));
      expect(l10n.p12ErrItemSoldOutNamed('Shiro'), contains('Shiro'));
      expect(l10n.p12ErrNetwork, isNotEmpty);
    }
  });
}
