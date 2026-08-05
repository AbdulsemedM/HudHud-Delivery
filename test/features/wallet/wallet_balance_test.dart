import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_balance_model.dart';

void main() {
  group('parseWalletBalanceResponse', () {
    test('parses documented balance envelope', () {
      final result = parseWalletBalanceResponse({
        'success': true,
        'data': {
          'balance': 2500.00,
          'currency': 'KES',
          'last_updated': '2024-01-15T10:30:00.000000Z',
        },
      });

      expect(result.balance, 2500.0);
      expect(result.currency, 'KES');
      expect(result.lastUpdated, '2024-01-15T10:30:00.000000Z');
    });

    test('parses flat balance payload', () {
      final result = parseWalletBalanceResponse({
        'balance': '100',
        'currency': 'ETB',
      });
      expect(result.balance, 100);
      expect(result.currency, 'ETB');
    });

    test('defaults empty response', () {
      final result = parseWalletBalanceResponse(null);
      expect(result.balance, 0);
      expect(result.currency, 'ETB');
    });
  });
}
