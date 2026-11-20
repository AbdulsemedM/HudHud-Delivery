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

  /// A URL built by concatenating an origin onto an already-absolute URL:
  /// `https://host` + `https://host/storage/x.png`. The first group is lazy
  /// and excludes `/?#`, so it can only ever match a BARE origin — which is
  /// what makes this safe against a legitimate nested URL in a query string
  /// (`https://host/go?to=https://other/x` has a `/` after the host, so the
  /// pattern does not match it at all).
  static final RegExp _duplicatedOrigin =
      RegExp(r'^(https?://[^/?#]+?)(https?://.+)$');

  static String? normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var value = raw.trim();

    // Fix duplicated host: https://api...https://api...
    //
    // This used to dedupe only `_storageHost` — the host this build is
    // currently pointed at. That silently did nothing for the case that
    // actually occurs: the API has moved host, and rows written before the
    // move carry a duplicated OLD origin. api.hudhuddelivery.com is exactly
    // that — the domain is suspended at the registrar and no longer resolves,
    // yet attachment rows written against it are still in the database. Under
    // the old code those URLs passed through untouched and rendered as a
    // broken image, because the host being duplicated was not the host in
    // `BASE_URL`. `chat_url_utils_test.dart` has asserted the correct
    // behaviour the whole time; nothing ever ran it.
    //
    // Matching the shape rather than a specific host fixes both, and keeps
    // working through the next host change.
    final duplicated = _duplicatedOrigin.firstMatch(value);
    if (duplicated != null) {
      value = duplicated.group(2)!;
    }

    // Retained for a duplicate that is not a leading bare origin, e.g. a
    // repeated host part-way through a path.
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
