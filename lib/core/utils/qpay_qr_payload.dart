import 'dart:convert';

enum QPayQrPayloadKind { rawValue, imageUrl, base64Image }

class QPayQrPayload {
  const QPayQrPayload({
    required this.kind,
    required this.displayValue,
    this.imageBytes,
  });

  final QPayQrPayloadKind kind;
  final String displayValue;
  final List<int>? imageBytes;

  static QPayQrPayload classify(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return const QPayQrPayload(
        kind: QPayQrPayloadKind.rawValue,
        displayValue: '',
      );
    }

    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return QPayQrPayload(
        kind: QPayQrPayloadKind.imageUrl,
        displayValue: value,
      );
    }

    if (lower.startsWith('data:image')) {
      final comma = value.indexOf(',');
      if (comma != -1) {
        final base64Part = value.substring(comma + 1);
        final bytes = _tryDecodeBase64(base64Part);
        if (bytes != null) {
          return QPayQrPayload(
            kind: QPayQrPayloadKind.base64Image,
            displayValue: base64Part,
            imageBytes: bytes,
          );
        }
      }
    }

    final decoded = _tryDecodeBase64(value);
    if (decoded != null && decoded.length > 32) {
      return QPayQrPayload(
        kind: QPayQrPayloadKind.base64Image,
        displayValue: value,
        imageBytes: decoded,
      );
    }

    return QPayQrPayload(
      kind: QPayQrPayloadKind.rawValue,
      displayValue: value,
    );
  }

  static List<int>? _tryDecodeBase64(String value) {
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}

/// How to render a QPay QR payload from the API.
enum QpayQrDisplayKind {
  qrValue,
  dataUrl,
  imageUrl,
  rawBase64,
}

class QpayQrPayload {
  const QpayQrPayload({
    required this.kind,
    required this.value,
  });

  final QpayQrDisplayKind kind;
  final String value;

  bool get isEmpty => value.isEmpty;
}

const _rawBase64Prefixes = ['iVBOR', '/9j/', 'R0lGOD', 'UklGR'];

bool isRawBase64QrPayload(String value) {
  for (final prefix in _rawBase64Prefixes) {
    if (value.startsWith(prefix)) return true;
  }
  return false;
}

/// Parses API `qr_code` without modifying the value.
QpayQrPayload parseQpayQrPayload(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const QpayQrPayload(kind: QpayQrDisplayKind.qrValue, value: '');
  }

  if (raw.startsWith('data:image')) {
    return QpayQrPayload(kind: QpayQrDisplayKind.dataUrl, value: raw);
  }

  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return QpayQrPayload(kind: QpayQrDisplayKind.imageUrl, value: raw);
  }

  if (isRawBase64QrPayload(raw)) {
    return QpayQrPayload(kind: QpayQrDisplayKind.rawBase64, value: raw);
  }

  return QpayQrPayload(kind: QpayQrDisplayKind.qrValue, value: raw);
}

/// Base64 payload suitable for [Image.memory], stripping data-URI prefix when needed.
String? base64ImageBytesFromQrPayload(QpayQrPayload payload) {
  switch (payload.kind) {
    case QpayQrDisplayKind.dataUrl:
      final comma = payload.value.indexOf(',');
      if (comma != -1) return payload.value.substring(comma + 1);
      return payload.value;
    case QpayQrDisplayKind.rawBase64:
      return payload.value;
    case QpayQrDisplayKind.qrValue:
    case QpayQrDisplayKind.imageUrl:
      return null;
  }
}
