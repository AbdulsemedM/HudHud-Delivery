# Security – API keys and secrets

## Exposed secret (Google Maps API key)

If you received an alert about an exposed Google API key in the repository:

1. **Rotate and revoke the exposed key**
   - In [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials, **delete or restrict** the key that was committed (e.g. in commit `54ba0b35`).
   - Create a **new** API key for Maps (Maps SDK for Android and Maps SDK for iOS), restrict it by app package name / bundle ID, and use the new key only in local or CI config (never commit it).

2. **Do not commit API keys or secrets.** Use the setup below so keys stay out of version control.

---

## Google Maps API key

### Android

- Add your key to **`android/local.properties`** (this file is gitignored):
  ```properties
  GOOGLE_MAPS_API_KEY=your_new_api_key_here
  ```
- Flutter may already create `local.properties` with `sdk.dir`. If the file exists, add the line above to it. If it does not exist, create the file with that line (and optionally `sdk.dir=...` if needed for your machine).

### iOS

- **Option A – Environment variable (recommended for CI and local)**  
  Set `GOOGLE_MAPS_API_KEY` when building so the key is never in the repo:
  - **Xcode**: Edit Scheme → Run → Arguments → Environment Variables → add `GOOGLE_MAPS_API_KEY` = your key.
  - **CI**: Set `GOOGLE_MAPS_API_KEY` in your CI environment (e.g. GitHub Actions secrets).
- **Option B – Info.plist (local only, do not commit)**  
  You can set `GoogleMapsAPIKey` in `ios/Runner/Info.plist` for local runs, but **do not commit** that change. The app reads the key from the built app’s Info.plist; the build script can inject it from `GOOGLE_MAPS_API_KEY` when that variable is set.

---

## Summary

- **Rotate/revoke** any key that was ever committed.
- **Android**: Put the new key in `android/local.properties` under `GOOGLE_MAPS_API_KEY`.
- **iOS**: Use the `GOOGLE_MAPS_API_KEY` environment variable when building (Xcode scheme or CI), or set it only locally in Info.plist and never commit it.
