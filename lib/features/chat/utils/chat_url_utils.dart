import 'package:hudhud_delivery/core/api/api_constants.dart';

/// Normalizes malformed attachment URLs from the chat API.
class ChatUrlUtils {
  ChatUrlUtils._();

  static const String _storageHost = 'https://hudapi.mbitrix.com';

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

    // Fix duplicated host: https://hudapi...https://hudapi...
    const host = 'https://hudapi.mbitrix.com';
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
      return '$_storageHost$value';
    }
    return '$_storageHost/storage/$value';
  }

  static String? _fromFilePath(String? filePath) {
    if (filePath == null || filePath.trim().isEmpty) return null;
    final path = filePath.trim();
    if (path.startsWith('http')) return path;
    final base = ApiConstants.baseUrl.replaceAll('/api/', '');
    return '$base/storage/$path';
  }
}
