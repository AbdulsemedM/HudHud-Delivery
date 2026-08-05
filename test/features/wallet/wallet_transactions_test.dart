import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/wallet/data/models/wallet_transaction_model.dart';

void main() {
  group('parseWalletTransactionsResponse', () {
    test('parses documented transactions + meta', () {
      final result = parseWalletTransactionsResponse({
        'success': true,
        'data': {
          'transactions': [
            {
              'id': 1,
              'type': 'credit',
              'amount': 1000.00,
              'balance': 2500.00,
              'description': 'Order #123 payment',
              'created_at': '2024-01-15T10:30:00.000000Z',
            },
            {
              'id': 2,
              'type': 'debit',
              'amount': -500.00,
              'balance': 1500.00,
              'description': 'Ride #456 payment',
              'created_at': '2024-01-15T09:15:00.000000Z',
            },
          ],
          'meta': {
            'current_page': 1,
            'total_pages': 5,
            'total_records': 100,
          },
        },
      });

      expect(result.transactions.length, 2);
      expect(result.transactions.first.isCredit, isTrue);
      expect(result.transactions.last.isDebit, isTrue);
      expect(result.transactions.first.balanceAfter, 2500.0);
      expect(result.currentPage, 1);
      expect(result.lastPage, 5);
      expect(result.total, 100);
    });

    test('falls back to Laravel data.data pagination', () {
      final result = parseWalletTransactionsResponse({
        'data': {
          'data': [
            {'id': 9, 'type': 'credit', 'amount': '50'},
          ],
          'current_page': 2,
          'last_page': 3,
          'total': 25,
        },
      });

      expect(result.transactions.length, 1);
      expect(result.transactions.first.id, 9);
      expect(result.currentPage, 2);
      expect(result.lastPage, 3);
      expect(result.total, 25);
    });
  });
}
