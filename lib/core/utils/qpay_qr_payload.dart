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
