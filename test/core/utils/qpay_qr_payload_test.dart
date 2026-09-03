import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/qpay_qr_payload.dart';

void main() {
  group('QPayQrPayload', () {
    test('classifies http url as imageUrl', () {
      final payload = QPayQrPayload.classify('https://example.com/qr.png');
      expect(payload.kind, QPayQrPayloadKind.imageUrl);
    });

    test('classifies data uri as base64 image', () {
      final payload = QPayQrPayload.classify(
        'data:image/png;base64,iVBORw0KGgo=',
      );
      expect(payload.kind, QPayQrPayloadKind.base64Image);
      expect(payload.imageBytes, isNotNull);
    });

    test('classifies emv string as raw value', () {
      final payload = QPayQrPayload.classify('000201010211');
      expect(payload.kind, QPayQrPayloadKind.rawValue);
      expect(payload.displayValue, '000201010211');
    });
  });
}
