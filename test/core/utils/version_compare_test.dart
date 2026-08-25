import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/version_compare.dart';

void main() {
  group('compareVersionStrings', () {
    test('orders simple versions', () {
      expect(compareVersionStrings('1.0.0', '1.0.1'), lessThan(0));
      expect(compareVersionStrings('1.2.0', '1.0.9'), greaterThan(0));
      expect(compareVersionStrings('2.0.0', '2.0.0'), 0);
    });

    test('ignores build metadata', () {
      expect(compareVersionStrings('1.0.0+11', '1.0.0+12'), 0);
      expect(compareVersionStrings('1.0.0+11', '1.0.1+1'), lessThan(0));
    });

    test('pads missing segments', () {
      expect(compareVersionStrings('1.0', '1.0.0'), 0);
      expect(compareVersionStrings('1', '1.0.1'), lessThan(0));
    });
  });
}
