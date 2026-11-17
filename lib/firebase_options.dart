// Firebase configuration for this app, in project hudhud-delivery-cus.
//
// WHAT WAS WRONG HERE, because it is worth knowing before editing this file.
//
// The previous version had exactly one entry, and `currentPlatform` returned it
// unconditionally:
//
//     static FirebaseOptions get currentPlatform {
//       return android;
//     }
//
// Two separate problems with that.
//
// 1. The appId it carried - 1:284030196855:android:a1ecd5ed33a6b18ebc3a72 -
//    is NOT this app. It belongs to a Firebase app registered under the
//    package name `com.example.hudhud_delivery`, the Flutter template's
//    placeholder, left over from whenever this project was first scaffolded.
//    This app's applicationId is `com.hudhud.userapp`, which is registered
//    separately as 1:284030196855:android:ba8023df0b1adaa0bc3a72.
//
//    The difference is not cosmetic: the `com.example...` app has NO SHA
//    certificate fingerprints registered, and `com.hudhud.userapp` has two
//    SHA-1s and a SHA-256. Google Sign-In on Android checks the signing
//    certificate against the fingerprints on the Firebase app the client
//    announces itself as, so signing in against the placeholder app could
//    never have worked in a signed build.
//
// 2. On iOS it returned the ANDROID options, and there is no
//    ios/Runner/GoogleService-Info.plist to fall back to, so Firebase came up
//    as the wrong app on every iPhone. That is why the APNs token wait added
//    in PR #13 could not succeed there, however correct the waiting was.
//
// The iOS app does exist and is fully configured - bundle id com.hudhud.user,
// App Store id 1588025471, team 4USB8Z9D4G - it had simply never been wired up
// here.
//
// The api keys below are the project's two auto-created Firebase keys, one for
// Android and one for Apple; the console lists exactly one of each. They are
// client configuration, not secrets: they ship inside every build and Google
// documents them as safe to publish.
//
// Regenerate this file with `flutterfire configure` rather than hand-editing
// it, and pick `com.hudhud.userapp` and `com.hudhud.user` when it asks - the
// project contains several near-identical HudHud Delivery entries.
//
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for this project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for $defaultTargetPlatform.',
        );
    }
  }

  /// Matches `applicationId` `com.hudhud.userapp` in android/app/build.gradle.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCmj-GfPdrGRTlX2mfy1dqiJi6JGBlFIP4',
    appId: '1:284030196855:android:ba8023df0b1adaa0bc3a72',
    messagingSenderId: '284030196855',
    projectId: 'hudhud-delivery-cus',
    storageBucket: 'hudhud-delivery-cus.firebasestorage.app',
  );

  /// Matches `PRODUCT_BUNDLE_IDENTIFIER` `com.hudhud.user` in the Xcode project.
  ///
  /// `iosClientId` is deliberately absent rather than guessed: the OAuth client
  /// for this bundle id exists, but the console truncates it and this file
  /// should not carry a half-remembered credential. Firebase initialises
  /// without it. Google Sign-In on iOS needs it AND the reversed-client URL
  /// scheme in Info.plist, neither of which this app has yet - running
  /// `flutterfire configure` sets up both.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBB0nsMbAYTrd6VCEiMQYpvfq281GqpGAA',
    appId: '1:284030196855:ios:1eb0eb28a4bf9549bc3a72',
    messagingSenderId: '284030196855',
    projectId: 'hudhud-delivery-cus',
    storageBucket: 'hudhud-delivery-cus.firebasestorage.app',
    iosBundleId: 'com.hudhud.user',
  );
}
