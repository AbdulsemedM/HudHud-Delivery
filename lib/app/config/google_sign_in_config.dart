/// Web OAuth client ID (Firebase project `hudhud-delivery-cus`, client type "Web").
/// Needed on Android so the ID token `aud` matches what the backend verifies.
/// Override at build time: `--dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=...`
///
/// **iOS:** Prefer `GoogleService-Info.plist` from Firebase. Optional override:
/// `--dart-define=GOOGLE_IOS_CLIENT_ID=...`
abstract final class GoogleSignInConfig {
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
    defaultValue:
        '284030196855-6ee7uapggibmro37i3tsi8r480vukra8.apps.googleusercontent.com',
  );

  /// iOS-only OAuth client ID; optional if `GoogleService-Info.plist` contains `CLIENT_ID`.
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );
}
