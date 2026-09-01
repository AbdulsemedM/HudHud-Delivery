import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/qpay_qr_payload.dart';

void main() {
  group('parseQpayQrPayload', () {
    test('detects plain QR value', () {
      const raw = '000201010212345678';
      final payload = parseQpayQrPayload(raw);
      expect(payload.kind, QpayQrDisplayKind.qrValue);
      expect(payload.value, raw);
    });

    test('detects data URL', () {
      const raw = 'data:image/png;base64,aVZORw0KGgo=';
      final payload = parseQpayQrPayload(raw);
      expect(payload.kind, QpayQrDisplayKind.dataUrl);
      expect(payload.value, raw);
    });

    test('detects HTTPS image URL', () {
      const raw = 'https://example.com/qr.png';
      final payload = parseQpayQrPayload(raw);
      expect(payload.kind, QpayQrDisplayKind.imageUrl);
      expect(payload.value, raw);
    });

    test('detects raw base64 PNG prefix', () {
      const raw = 'iVBORw0KGgoAAAANSUhEUg';
      final payload = parseQpayQrPayload(raw);
      expect(payload.kind, QpayQrDisplayKind.rawBase64);
      expect(payload.value, raw);
    });

    test('base64ImageBytesFromQrPayload strips data URI prefix', () {
      const raw = 'data:image/png;base64,aVZORw0KGgo=';
      final payload = parseQpayQrPayload(raw);
      expect(base64ImageBytesFromQrPayload(payload), 'aVZORw0KGgo=');
    });
  });
}
