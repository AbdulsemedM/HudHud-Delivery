import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/validation/login_validators.dart';

void main() {
  group('normalizeLoginPhone', () {
    test('normalizes Ethiopian national number with +251', () {
      expect(
        normalizeLoginPhone('+251', '912345678'),
        '251912345678',
      );
    });

    test('normalizes local trunk prefix', () {
      expect(
        normalizeLoginPhone('+251', '0912345678'),
        '251912345678',
      );
    });
  });
}
