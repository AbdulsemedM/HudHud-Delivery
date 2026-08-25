import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/notifications/notification_events.dart';

void main() {
  group('normalizeEvent', () {
    test('lowercases and normalises separators', () {
      expect(normalizeEvent('ORDER_CREATED'), 'order_created');
      expect(normalizeEvent('ETA-UPDATED'), 'eta_updated');
    });

    test('returns empty for null or blank', () {
      expect(normalizeEvent(null), '');
      expect(normalizeEvent(''), '');
    });
  });

  group('normalizeCityCode', () {
    test('converts city names to topic codes', () {
      expect(normalizeCityCode('Addis Ababa'), 'addis_ababa');
      expect(normalizeCityCode('  Jigjiga  '), 'jigjiga');
    });
  });

  group('parseOrderIdFromPayload', () {
    test('reads order id from common keys', () {
      expect(parseOrderIdFromPayload({'order_id': '42'}), 42);
      expect(parseOrderIdFromPayload({'orderId': '7'}), 7);
      expect(parseOrderIdFromPayload({'id': '99'}), 99);
      expect(parseOrderIdFromPayload({'order_number': 'PKG-1'}), isNull);
    });
  });

  group('event classification', () {
    test('identifies customer order events', () {
      expect(isCustomerOrderEvent('DELIVERY_COMPLETED'), isTrue);
      expect(isCustomerOrderEvent('wallet_low'), isFalse);
    });

    test('identifies security events', () {
      expect(isSecurityEvent('PHONE_VERIFICATION'), isTrue);
      expect(isSecurityEvent('ORDER_CREATED'), isFalse);
    });
  });
}
