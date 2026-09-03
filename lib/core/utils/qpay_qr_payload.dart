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
