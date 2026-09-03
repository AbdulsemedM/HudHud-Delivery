import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/wallet/utils/wallet_funding_methods.dart';

void main() {
  group('filterWalletFundingMethods', () {
    test('excludes wallet and cash_on_delivery', () {
      final filtered = filterWalletFundingMethods([
        {'id': 'wallet', 'name': 'Wallet', 'enabled': true},
        {'id': 'cash_on_delivery', 'name': 'COD', 'enabled': true},
        {'id': 'waafi', 'name': 'Waafi', 'enabled': true},
        {'id': 'edahab', 'name': 'eDahab', 'enabled': true},
      ]);
      final ids = filtered.map((m) => m['id']).toSet();
      expect(ids, containsAll(['waafi', 'edahab']));
      expect(ids, isNot(contains('wallet')));
      expect(ids, isNot(contains('cash_on_delivery')));
    });

    test('includes qpay when present', () {
      final filtered = filterWalletFundingMethods([
        {'id': 'qpay', 'name': 'QPay', 'enabled': true},
        {'id': 'waafi', 'name': 'Waafi', 'enabled': true},
      ]);
      expect(filtered.map((m) => m['id']), contains('qpay'));
    });

    test('falls back to default funding methods', () {
      final filtered = filterWalletFundingMethods([]);
      expect(
        filtered.map((m) => m['id']).toSet(),
        equals(kDefaultWalletFundingMethods.map((m) => m['id']).toSet()),
      );
      expect(filtered.map((m) => m['id']), contains('qpay'));
    });
  });

  group('QPay availability', () {
    test('shows qpay when can_use is omitted (legacy API)', () {
      expect(
        isQPayMethodAvailable({'id': 'qpay', 'enabled': true}),
        isTrue,
      );
    });

    test('hides qpay when can_use is false', () {
      expect(
        isQPayMethodAvailable({'id': 'qpay', 'enabled': true, 'can_use': false}),
        isFalse,
      );
    });

    test('hides qpay when not configured', () {
      expect(
        isQPayMethodAvailable({
          'id': 'qpay',
          'enabled': true,
          'can_use': true,
          'availability_code': 'QPAY_NOT_CONFIGURED',
        }),
        isFalse,
      );
    });

    test('shows qpay when explicitly usable', () {
      expect(
        isQPayMethodAvailable({
          'id': 'qpay',
          'enabled': true,
          'can_use': true,
        }),
        isTrue,
      );
    });

    test('applyQPayAvailabilityRules filters unavailable qpay', () {
      final filtered = applyQPayAvailabilityRules([
        {'id': 'waafi', 'enabled': true},
        {'id': 'qpay', 'enabled': true, 'can_use': false},
        {
          'id': 'qpay',
          'enabled': true,
          'can_use': true,
        },
      ]);
      expect(filtered.length, 2);
      expect(filtered.any((m) => m['id'] == 'waafi'), isTrue);
      expect(
        filtered.where((m) => m['id'] == 'qpay').length,
        1,
      );
    });

    test('sortWalletFundingMethods puts qpay first then ebirr coop/kaafi', () {
      final sorted = sortWalletFundingMethods([
        {'id': 'waafi', 'name': 'Waafi'},
        {'id': 'ebirr_kaafi', 'name': 'Kaafi'},
        {'id': 'qpay', 'name': 'QPay'},
        {'id': 'ebirr_coop', 'name': 'Coop'},
      ]);
      expect(sorted.map((m) => m['id']).toList(), [
        'qpay',
        'ebirr_coop',
        'ebirr_kaafi',
        'waafi',
      ]);
    });

    test('ensureQPayInWalletMethods injects qpay when API omits it', () {
      final methods = ensureQPayInWalletMethods([
        {'id': 'waafi', 'name': 'Waafi', 'enabled': true},
      ]);
      expect(methods.first['id'], 'qpay');
      expect(methods.length, 2);
    });
  });

  group('buildWalletTopupBody / withdraw body', () {
    test('topup uses payment_method_code', () {
      final body = buildWalletTopupBody(
        paymentMethodCode: 'waafi',
        amount: 1000,
        currency: 'KES',
        paymentDetails: {'phone': '254712345678'},
      );
      expect(body['payment_method_code'], 'waafi');
      expect(body['amount'], 1000);
      expect(body['currency'], 'KES');
      expect(body['payment_details'], {'phone': '254712345678'});
      expect(body.containsKey('method'), isFalse);
      expect(body.containsKey('wallet_id'), isFalse);
    });

    test('withdraw includes wallet_id and currency', () {
      final body = buildWalletWithdrawBody(
        paymentMethodCode: 'edahab',
        amount: 500,
        currency: 'ETB',
        walletId: 123,
        paymentDetails: {'phone': '656013956'},
      );
      expect(body['payment_method_code'], 'edahab');
      expect(body['amount'], 500);
      expect(body['currency'], 'ETB');
      expect(body['wallet_id'], 123);
      expect(body['payment_details'], {'phone': '656013956'});
    });
  });
}
