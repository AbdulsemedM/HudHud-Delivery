import 'package:hudhud_delivery/core/api/api_constants.dart';

/// Normalizes malformed attachment URLs from the chat API.
class ChatUrlUtils {
  ChatUrlUtils._();

  static String get _storageHost {
    final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  static String? resolveAttachmentUrl({
    String? url,
    String? fullPath,
    String? filePath,
  }) {
    final candidates = [url, fullPath, _fromFilePath(filePath)];
    for (final raw in candidates) {
      final normalized = normalize(raw);
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  static String? normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var value = raw.trim();

    // Fix duplicated host: https://api...https://api...
    final host = _storageHost;
    if (value.contains('$host$host')) {
      value = value.replaceAll('$host$host', host);
    }
    final duplicateIndex = value.indexOf(host, host.length);
    if (duplicateIndex > 0) {
      value = value.substring(duplicateIndex);
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$host$value';
    }
    return '$host/storage/$value';
  }

  static String? _fromFilePath(String? filePath) {
    if (filePath == null || filePath.trim().isEmpty) return null;
    final path = filePath.trim();
    if (path.startsWith('http')) return path;
    final base = ApiConstants.baseUrl.replaceAll('/api/', '');
    return '$base/storage/$path';
  }
}
