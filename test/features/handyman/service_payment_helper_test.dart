import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/features/payment/utils/service_payment_mapping.dart';

void main() {
  group('filterServicePaymentMethods', () {
    test('excludes cash_on_delivery and keeps allowed methods', () {
      final filtered = filterServicePaymentMethods([
        {'id': 'wallet', 'name': 'Wallet', 'enabled': true},
        {'id': 'cash_on_delivery', 'name': 'COD', 'enabled': true},
        {'id': 'waafi', 'name': 'Waafi', 'enabled': true},
        {'id': 'card', 'name': 'Card', 'enabled': true},
      ]);

      final ids = filtered.map((m) => m['id']).toList();
      expect(ids, containsAll(['wallet', 'waafi']));
      expect(ids, isNot(contains('cash_on_delivery')));
      expect(ids, isNot(contains('card')));
    });

    test('falls back to default list without COD when empty', () {
      final filtered = filterServicePaymentMethods([]);
      final ids = filtered.map((m) => m['id']).toSet();
      expect(
        ids,
        equals(kDefaultServicePaymentMethods.map((m) => m['id']).toSet()),
      );
      expect(ids, isNot(contains('cash_on_delivery')));
    });
  });

  group('servicePaymentPathForMethod', () {
    test('maps UI codes to convenience paths', () {
      expect(
        servicePaymentPathForMethod('wallet'),
        ApiConstants.paymentsServiceWallet,
      );
      expect(
        servicePaymentPathForMethod('waafi'),
        ApiConstants.paymentsServiceWaafipay,
      );
      expect(
        servicePaymentPathForMethod('edahab'),
        ApiConstants.paymentsServiceEdahab,
      );
      expect(
        servicePaymentPathForMethod('sahay'),
        ApiConstants.paymentsServiceSahay,
      );
      expect(
        servicePaymentPathForMethod('ebirr'),
        ApiConstants.paymentsServiceEbirr,
      );
      expect(
        servicePaymentPathForMethod('ebirr_kaafi'),
        ApiConstants.paymentsServiceEbirr,
      );
      expect(
        servicePaymentPathForMethod('ebirr_coop'),
        ApiConstants.paymentsServiceEbirr,
      );
    });

    test('throws for unsupported method', () {
      expect(
        () => servicePaymentPathForMethod('cash_on_delivery'),
        throwsArgumentError,
      );
    });
  });

  group('buildServicePaymentBody', () {
    test('wallet body has only service_request_id', () {
      final body = buildServicePaymentBody(
        methodCode: 'wallet',
        serviceRequestId: 42,
        paymentDetails: {'phone': '254712345678', 'use_hpp': true},
      );
      expect(body, equals({'service_request_id': 42}));
    });

    test('waafi includes phone and use_hpp', () {
      final body = buildServicePaymentBody(
        methodCode: 'waafi',
        serviceRequestId: 42,
        paymentDetails: {'phone': '0712345678', 'use_hpp': true},
      );
      expect(body['service_request_id'], 42);
      expect(body['phone'], '254712345678');
      expect(body['use_hpp'], isTrue);
      expect(body.containsKey('provider'), isFalse);
    });

    test('edahab and sahay include normalized phone', () {
      final edahab = buildServicePaymentBody(
        methodCode: 'edahab',
        serviceRequestId: 1,
        paymentDetails: {'phone': '656013956'},
      );
      expect(edahab['phone'], '656013956');

      final sahay = buildServicePaymentBody(
        methodCode: 'sahay',
        serviceRequestId: 1,
        paymentDetails: {'phone': '0911679409'},
      );
      expect(sahay['phone'], '251911679409');
    });

    test('ebirr always forces provider ebirr', () {
      final body = buildServicePaymentBody(
        methodCode: 'ebirr',
        serviceRequestId: 42,
        paymentDetails: {
          'phone': '251915741199',
          'provider': 'kaafi',
        },
      );
      expect(body['service_request_id'], 42);
      expect(body['phone'], '251915741199');
      expect(body['provider'], 'ebirr');
    });

    test('ebirr provider-specific codes map provider from method code', () {
      final kaafi = buildServicePaymentBody(
        methodCode: 'ebirr_kaafi',
        serviceRequestId: 42,
        paymentDetails: {'phone': '251915741199'},
      );
      expect(kaafi['provider'], 'kaafi');

      final coop = buildServicePaymentBody(
        methodCode: 'ebirr_coop',
        serviceRequestId: 42,
        paymentDetails: {'phone': '251915741199'},
      );
      expect(coop['provider'], 'coop');
    });
  });
}
