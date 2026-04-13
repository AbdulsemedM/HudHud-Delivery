/// Optional Web OAuth client ID (Firebase Console → Project settings → Your apps → Web client).
/// On Android, setting [serverClientId] is usually required so Google returns an ID token for the backend.
///
/// Build: `flutter run --dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
///
/// **iOS:** Prefer a full `GoogleService-Info.plist` from Firebase (includes `CLIENT_ID`). If you
/// still need an override, use the **iOS** OAuth client ID (not Android):
/// `--dart-define=GOOGLE_IOS_CLIENT_ID=xxx.apps.googleusercontent.com`
abstract final class GoogleSignInConfig {
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// iOS-only OAuth client ID; optional if `GoogleService-Info.plist` contains `CLIENT_ID`.
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );
}
