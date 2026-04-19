import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_sign_in_config.dart';

/// Thrown when the user dismisses the Google sign-in UI (no snackbar).
class GoogleSignInUserCancelled implements Exception {}

bool _googleSignInInitialized = false;

Future<void> _ensureGoogleSignInInitialized() async {
  if (_googleSignInInitialized) return;
  final scid = GoogleSignInConfig.serverClientId.trim();
  final iosId = GoogleSignInConfig.iosClientId.trim();
  try {
    await GoogleSignIn.instance.initialize(
      // iOS: required if GoogleService-Info.plist has no CLIENT_ID (see Info.plist URL scheme too).
      clientId: !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.iOS &&
              iosId.isNotEmpty
          ? iosId
          : null,
      serverClientId: scid.isNotEmpty ? scid : null,
    );
    _googleSignInInitialized = true;
  } catch (e, st) {
    debugPrint('[GoogleSignIn] initialize failed: $e');
    debugPrint('$st');
    rethrow;
  }
}

/// Runs the platform Google sign-in flow and returns an ID token for [POST /auth/google-login].
Future<String> obtainGoogleIdToken() async {
  await _ensureGoogleSignInInitialized();
  try {
    final GoogleSignInAccount account =
        await GoogleSignIn.instance.authenticate(
      scopeHint: const <String>['email', 'profile'],
    );
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      final msg = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? 'Google did not return an ID token. iOS needs: (1) `CLIENT_ID` and '
              '`REVERSED_CLIENT_ID` in ios/Runner/GoogleService-Info.plist from Firebase, '
              '(2) `GOOGLE_IOS_REVERSED_CLIENT_ID` in ios/Flutter/LocalSecrets.xcconfig for the '
              'URL scheme, (3) optional `--dart-define=GOOGLE_IOS_CLIENT_ID=...` if plist has no '
              'CLIENT_ID, (4) `--dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=...` for backend ID token.'
          : 'Google did not return an ID token. On Android, ensure the Web OAuth client id '
              'is set (default in GoogleSignInConfig) or pass '
              '--dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=...';
      debugPrint('[GoogleSignIn] $msg');
      throw StateError(msg);
    }
    return idToken;
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled ||
        e.code == GoogleSignInExceptionCode.interrupted) {
      debugPrint('[GoogleSignIn] cancelled or interrupted (${e.code})');
      throw GoogleSignInUserCancelled();
    }
    debugPrint('[GoogleSignIn] ${e.code}: ${e.description ?? e.toString()}');
    rethrow;
  } catch (e, st) {
    debugPrint('[GoogleSignIn] unexpected error: $e');
    debugPrint('$st');
    rethrow;
  }
}
