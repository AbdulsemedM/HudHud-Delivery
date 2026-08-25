import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';

void main() {
  group('splitPhoneForDisplay', () {
    test('splits +251 international format', () {
      final parts = splitPhoneForDisplay('+251912345678');
      expect(parts.countryDialCode, '+251');
      expect(parts.nationalNumber, '912345678');
    });

    test('splits 251 without plus', () {
      final parts = splitPhoneForDisplay('251912345678');
      expect(parts.countryDialCode, '+251');
      expect(parts.nationalNumber, '912345678');
    });

    test('splits +254 Kenya format', () {
      final parts = splitPhoneForDisplay('+254712345678');
      expect(parts.countryDialCode, '+254');
      expect(parts.nationalNumber, '712345678');
    });

    test('splits local 0-prefix as national only', () {
      final parts = splitPhoneForDisplay('0912345678');
      expect(parts.countryDialCode, '+251');
      expect(parts.nationalNumber, '912345678');
    });

    test('empty phone uses default dial code', () {
      final parts = splitPhoneForDisplay('');
      expect(parts.countryDialCode, '+251');
      expect(parts.nationalNumber, '');
    });
  });

  group('cleanNationalPhoneDigits', () {
    test('removes leading zero', () {
      expect(cleanNationalPhoneDigits('0912345678'), '912345678');
    });

    test('strips non-digits', () {
      expect(cleanNationalPhoneDigits('912-345-678'), '912345678');
    });
  });
}
