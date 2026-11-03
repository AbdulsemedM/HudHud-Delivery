/// Build-time configuration.
///
/// Values come from `--dart-define` / `--dart-define-from-file` at build time
/// (see ENV_SETUP_NATIVE.md). Nothing is bundled as an asset, and only
/// non-secret values belong here — native secrets such as
/// GOOGLE_MAPS_API_KEY are injected through Gradle / Xcode instead.
///
/// Example:
///   flutter run --dart-define=BASE_URL=https://staging.example.com/api/
///   shorebird release android -- --dart-define-from-file=env/prod.json

/// Production API (same default as the HudHud driver app).
const String kDefaultApiBaseUrl = 'https://api.hudhuddelivery.com/api/';

const String _baseUrlDefine =
    String.fromEnvironment('BASE_URL', defaultValue: kDefaultApiBaseUrl);

/// Kept for call-site compatibility with the old `.env` loader.
/// Configuration is now compile-time, so there is nothing to load.
Future<void> loadAppEnv() async {}

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

  static final String _baseUrl = normalizeApiBaseUrl(
    _baseUrlDefine.trim().isEmpty ? kDefaultApiBaseUrl : _baseUrlDefine,
  );

  /// `BASE_URL` dart-define, falling back to [kDefaultApiBaseUrl].
  static String get baseUrl => _baseUrl;
}
