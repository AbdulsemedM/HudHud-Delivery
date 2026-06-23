import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/payment/utils/payment_methods_parser.dart';

void main() {
  group('parsePaymentMethodsList', () {
    final sampleList = [
      {
        'code': 'ebirr',
        'name': 'eBirr',
        'description': 'Pay with eBirr',
        'is_active': true,
        'sort_order': '2',
      },
      {
        'code': 'wallet',
        'name': 'Wallet',
        'description': 'Pay from wallet',
        'is_active': true,
        'sort_order': '1',
      },
      {
        'code': 'qpay',
        'name': 'QPay',
        'description': 'Scan QR',
        'is_active': true,
        'sort_order': '7',
      },
      {
        'code': 'telebirr',
        'name': 'TeleBirr',
        'description': 'Inactive',
        'is_active': false,
        'sort_order': '3',
      },
      {
        'code': 'sahay',
        'name': 'Sahay',
        'description': 'USSD',
        'is_active': true,
        'sort_order': '4',
      },
      {
        'code': 'cash_on_delivery',
        'name': 'Cash on Delivery',
        'is_active': true,
        'sort_order': '5',
      },
      {
        'code': 'waafi',
        'name': 'Waafi',
        'is_active': true,
        'sort_order': '6',
      },
    ];

    test('parses active methods sorted by sort_order', () {
      final methods = parsePaymentMethodsList(sampleList);
      expect(methods.length, 7);
      expect(methods.first['id'], 'wallet');
      expect(methods.last['id'], 'qpay');
      expect(methods.first['enabled'], isTrue);
    });

    test('maps code to id and keeps inactive methods in raw parse', () {
      final methods = parsePaymentMethodsList(sampleList);
      final telebirr = methods.firstWhere((m) => m['id'] == 'telebirr');
      expect(telebirr['enabled'], isFalse);
      expect(telebirr['name'], 'TeleBirr');
    });

    test('coerces map items from generic Map type', () {
      final methods = parsePaymentMethodsList([
        Map<Object?, Object?>.from({
          'code': 'edahab',
          'name': 'Edahab',
          'is_active': true,
          'sort_order': 1,
        }),
      ]);
      expect(methods.single['id'], 'edahab');
      expect(methods.single['description'], 'Pay with Edahab');
    });

    test('returns empty list for invalid input', () {
      expect(parsePaymentMethodsList(null), isEmpty);
      expect(parsePaymentMethodsList('bad'), isEmpty);
    });
  });
}
