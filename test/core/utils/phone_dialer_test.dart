import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/phone_dialer.dart';

void main() {
  group('PhoneDialer.telPath', () {
    // The courier's "Call" dialed 251904330066: the dialer read it as a local
    // number and the call failed. It must dial +251904330066.
    test('the stored form 2519… gets its "+"', () {
      expect(PhoneDialer.telPath('251904330066'), '+251904330066');
    });

    test('every Ethiopian mobile form dials the same number', () {
      for (final input in [
        '251904330066',
        '+251904330066',
        '+251 90 433 0066',
        '0904330066',
        '904330066',
        '2510904330066',
      ]) {
        expect(PhoneDialer.telPath(input), '+251904330066', reason: input);
      }
    });

    test('other countries keep or gain their "+"', () {
      expect(PhoneDialer.telPath('+252634000000'), '+252634000000');
      expect(PhoneDialer.telPath('252634000000'), '+252634000000');
      expect(PhoneDialer.telPath('00252634000000'), '+252634000000');
    });

    test('short codes and local landlines are left alone', () {
      expect(PhoneDialer.telPath('9491'), '9491');
      expect(PhoneDialer.telPath('0111234567'), '0111234567');
    });

    test('nothing to dial', () {
      expect(PhoneDialer.telPath(null), isNull);
      expect(PhoneDialer.telPath(''), isNull);
      expect(PhoneDialer.telPath(' - '), isNull);
    });

    test('telUri is a tel: URI with the "+"', () {
      expect(PhoneDialer.telUri('251904330066').toString(), 'tel:+251904330066');
    });
  });
}
