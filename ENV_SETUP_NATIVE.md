# Flutter Native `.env` Setup (No Assets)

This guide shows how to set up environment-based secrets in Flutter **without** adding `.env` to `flutter.assets`.

Use this pattern for secrets like `GOOGLE_MAPS_API_KEY` that should be injected through Android/iOS native layers.

---

## Why this setup

- Avoids bundling `.env` into the app package via Flutter assets.
- Keeps secrets out of Dart source and pubspec assets.
- Works with platform-native SDK initialization (Google Maps).
- Supports CI/CD by setting platform environment variables.

---

## 1) Root env files

Create these files in the project root:

### `.env`
```env
GOOGLE_MAPS_API_KEY=your_real_key_here
```

### `.env.example`
```env
GOOGLE_MAPS_API_KEY=
```

### `.gitignore` additions
```gitignore
.env
.env.local
.env.*.local
```

---

## 2) Do NOT add `.env` to Flutter assets

In `pubspec.yaml`, make sure `.env` is not listed:

```yaml
flutter:
  assets:
    # do not add .env here
```

Also remove `flutter_dotenv` if you only used it for secret keys.

---

## 3) Android setup (`android/app/build.gradle`)

Read key from project root `.env`, with fallback to `android/local.properties`.

```gradle
plugins {
    id "com.android.application"
    id "org.jetbrains.kotlin.android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localProperties.load(new FileInputStream(localPropertiesFile))
}

// Read GOOGLE_MAPS_API_KEY from project root .env, fallback to android/local.properties
def googleMapsApiKey = ''
def projectRoot = rootProject.rootDir.parentFile
def envFile = projectRoot != null ? new File(projectRoot, '.env') : null
if (envFile != null && envFile.exists()) {
    envFile.withReader('UTF-8') { reader ->
        reader.eachLine { line ->
            def m = line =~ /^\s*GOOGLE_MAPS_API_KEY\s*=\s*(.+)\s*$/
            if (m) {
                googleMapsApiKey = m.group(1).trim().replaceAll(/^["']|["']$/, '')
            }
        }
    }
}
if (!googleMapsApiKey) {
    googleMapsApiKey = localProperties.getProperty('GOOGLE_MAPS_API_KEY', '').trim()
}

android {
    namespace = "com.example.yourapp"
    compileSdk = 35

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.example.yourapp"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion 35
        versionCode flutter.versionCode.toInteger()
        versionName flutter.versionName

        // AndroidManifest placeholder
        manifestPlaceholders = [googleMapsApiKey: googleMapsApiKey]

        // Runtime access via BuildConfig if needed
        buildConfigField "String", "GOOGLE_MAPS_API_KEY", "\"${googleMapsApiKey.replace('"', '\\"')}\""
    }
}
```

In `android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${googleMapsApiKey}" />
```

---

## 4) iOS setup (`ios/Runner/AppDelegate.swift`)

Initialize Google Maps using:
1. `Info.plist` key (`GoogleMapsAPIKey`) if present
2. Fallback to environment variable `GOOGLE_MAPS_API_KEY`

Also expose key to Dart via method channel.

```swift
import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let configChannelName = "your_app/config"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let apiKey = resolvedGoogleMapsApiKey()
    if !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: configChannelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self else { return }
        if call.method == "getGoogleMapsApiKey" {
          result(self.resolvedGoogleMapsApiKey())
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func resolvedGoogleMapsApiKey() -> String {
    let infoKey = (Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if !infoKey.isEmpty { return infoKey }

    let envKey = (ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return envKey
  }
}
```

Optional in `ios/Runner/Info.plist`:
```xml
<key>GoogleMapsAPIKey</key>
<string></string>
```

For local iOS run, add env var in Xcode scheme:
- Product -> Scheme -> Edit Scheme -> Run -> Arguments -> Environment Variables
- `GOOGLE_MAPS_API_KEY=your_real_key_here`

---

## 5) Dart method-channel provider

Create `lib/app/config/google_maps_api_key_provider.dart`:

```dart
import 'package:flutter/services.dart';

class GoogleMapsApiKeyProvider {
  GoogleMapsApiKeyProvider._();

  static const _channel = MethodChannel('your_app/config');
  static String? _cachedKey;

  static Future<String> getKey() async {
    if (_cachedKey != null) return _cachedKey!;
    try {
      final key = await _channel.invokeMethod<String>('getGoogleMapsApiKey');
      _cachedKey = key ?? '';
      return _cachedKey!;
    } on PlatformException {
      _cachedKey = '';
      return '';
    }
  }
}
```

Usage:
```dart
final apiKey = await GoogleMapsApiKeyProvider.getKey();
```

---

## 6) CI/CD recommendation

- Keep `.env` local only.
- In CI, inject `GOOGLE_MAPS_API_KEY` as a secure environment variable.
- For Android, you can also provide it via `android/local.properties` during pipeline setup.

---

## 7) Verification checklist

1. `flutter clean`
2. `flutter pub get`
3. `flutter run`
4. If map is blank:
   - Confirm Maps/Places/Geocoding APIs are enabled in Google Cloud.
   - Confirm package name / bundle ID restrictions and Android SHA-1.
   - Confirm key is present in `.env` or platform env.

---

## 8) Common mistakes to avoid

- Adding `.env` under `flutter.assets`.
- Committing `.env` to git.
- Reading secrets directly from Dart-only env libraries for native SDK init.
- Forgetting to restart/rebuild after changing key values.

