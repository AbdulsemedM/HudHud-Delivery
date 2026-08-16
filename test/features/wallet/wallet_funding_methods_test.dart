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

    test('falls back to default funding methods', () {
      final filtered = filterWalletFundingMethods([]);
      expect(
        filtered.map((m) => m['id']).toSet(),
        equals(kDefaultWalletFundingMethods.map((m) => m['id']).toSet()),
      );
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
