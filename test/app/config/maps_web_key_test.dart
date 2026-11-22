import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';

/// The Maps SDK key and the web-services key must not be confused.
///
/// Google applies an "Android apps" application restriction to the Maps SDKs
/// ONLY. The maps.googleapis.com web services — Places autocomplete, place
/// details, nearby search, Geocoding, Directions — reject a key carrying such
/// a restriction with REQUEST_DENIED.
///
/// That makes this the nastiest kind of regression, because it fails asymmetrically:
/// the map still draws, so the app looks fine, and the only thing that breaks
/// is address autocomplete — which is how a customer enters a delivery address.
/// Nobody notices until an order cannot be placed.
///
/// It nearly shipped exactly that way: the single shared key worked only
/// because it was unrestricted, and locking it down to our package names would
/// have taken address search with it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('hudhud_delivery/config');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// [webKey] null means the native side does not implement the method at all,
  /// which is what an older binary does.
  void stubNative({required String sdkKey, String? webKey}) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getGoogleMapsApiKey':
          return sdkKey;
        case 'getGoogleMapsWebKey':
          if (webKey == null) {
            throw MissingPluginException('No implementation for getGoogleMapsWebKey');
          }
          return webKey;
        default:
          throw MissingPluginException(call.method);
      }
    });
  }

  setUp(GoogleMapsApiKeyProvider.resetForTest);

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    GoogleMapsApiKeyProvider.resetForTest();
  });

  test('the two keys are read from two different native methods', () async {
    stubNative(sdkKey: 'SDK-KEY', webKey: 'WEB-KEY');

    expect(await GoogleMapsApiKeyProvider.getKey(), 'SDK-KEY');
    expect(await GoogleMapsApiKeyProvider.getWebKey(), 'WEB-KEY');
  });

  /// An older native binary answers with MissingPluginException. Returning
  /// empty there would break address search for every user on that build,
  /// which is worse than the restriction problem this split is solving.
  test('an older binary without the web method falls back to the SDK key', () async {
    stubNative(sdkKey: 'SDK-KEY', webKey: null);

    expect(await GoogleMapsApiKeyProvider.getWebKey(), 'SDK-KEY');
  });

  /// Same reasoning for a build where only the old secret is configured:
  /// build.gradle hands back an empty string rather than failing the build.
  test('an empty web key falls back to the SDK key rather than to empty', () async {
    stubNative(sdkKey: 'SDK-KEY', webKey: '');

    expect(await GoogleMapsApiKeyProvider.getWebKey(), 'SDK-KEY');
  });

  test('each key is fetched from the platform only once', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return call.method == 'getGoogleMapsWebKey' ? 'WEB-KEY' : 'SDK-KEY';
    });

    await GoogleMapsApiKeyProvider.getWebKey();
    await GoogleMapsApiKeyProvider.getWebKey();
    await GoogleMapsApiKeyProvider.getWebKey();

    expect(calls, 1);
  });

  /// The guard that actually prevents the regression coming back.
  ///
  /// Reviewing a diff, `getKey()` and `getWebKey()` differ by three characters
  /// and both compile, both run, and both return a usable-looking string. The
  /// only thing that distinguishes them is which Google endpoint accepts the
  /// result — which no unit test of these services can observe without calling
  /// Google. So assert the rule at the source level instead: anything that
  /// builds a maps.googleapis.com URL must take the web key.
  test('every maps.googleapis.com caller uses the web key, not the SDK key', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final source = entity.readAsStringSync();
      if (!source.contains('maps.googleapis.com')) continue;
      if (!source.contains('GoogleMapsApiKeyProvider.getKey()')) continue;

      offenders.add(entity.path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These files call maps.googleapis.com with the Maps SDK key:\n  ${offenders.join('\n  ')}\n\n'
          'The SDK key carries an Android/iOS application restriction, which Google '
          'applies only to the Maps SDKs. Web-service endpoints reject it with '
          'REQUEST_DENIED, and the failure is invisible — the map keeps drawing and '
          'only address search dies. Use GoogleMapsApiKeyProvider.getWebKey().',
    );
  });
}
