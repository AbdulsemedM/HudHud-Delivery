import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/services/force_update_service.dart';

void main() {
  group('decideUpdateGate', () {
    test('forces when below minimum', () {
      expect(
        decideUpdateGate(
          current: '1.0.0',
          minimum: '1.0.1',
          latest: '1.1.0',
        ),
        UpdateGate.force,
      );
    });

    test('suggests soft when between minimum and latest', () {
      expect(
        decideUpdateGate(
          current: '1.0.1',
          minimum: '1.0.0',
          latest: '1.1.0',
        ),
        UpdateGate.soft,
      );
    });

    test('none when current meets latest', () {
      expect(
        decideUpdateGate(
          current: '1.1.0',
          minimum: '1.0.0',
          latest: '1.1.0',
        ),
        UpdateGate.none,
      );
    });

    test('none when latest is empty', () {
      expect(
        decideUpdateGate(
          current: '1.0.1',
          minimum: '1.0.0',
          latest: '',
        ),
        UpdateGate.none,
      );
    });
  });
}
