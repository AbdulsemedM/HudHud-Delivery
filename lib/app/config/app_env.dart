import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads root [`.env`] into [dotenv] before Dio / API clients start.
Future<void> loadAppEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Failed to load .env: $e');
      debugPrint('$st');
    }
    rethrow;
  }
}

/// Normalizes [BASE_URL] so it ends with `/api/`.
String normalizeApiBaseUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) {
    throw ArgumentError('BASE_URL must not be empty');
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  if (!url.toLowerCase().endsWith('/api')) {
    url = '$url/api';
  }
  return '$url/';
}

class ApiEnv {
  ApiEnv._();

  /// Reads `BASE_URL` from `.env` only — no hardcoded fallback.
  static String get baseUrl {
    if (!dotenv.isInitialized) {
      throw StateError('Env not loaded. Call loadAppEnv() before using the API.');
    }
    final fromEnv = dotenv.maybeGet('BASE_URL');
    if (fromEnv == null || fromEnv.trim().isEmpty) {
      throw StateError('BASE_URL is missing in .env');
    }
    return normalizeApiBaseUrl(fromEnv);
  }
}
