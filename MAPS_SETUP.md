# Google Maps setup

The app uses **Google Maps** for location search and delivery flows. Maps will not work until you add a valid **Google Maps API key** for Android and (if you build for iOS) for iOS.

## 1. Get an API key

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Create or select a project.
3. Go to **APIs & Services** → **Library** and enable:
   - **Maps SDK for Android**
   - **Maps SDK for iOS** (if you build for iOS)
   - **Places API** (for “Where to?” place search suggestions; same key is used)
   - **Geocoding API** (for reverse geocoding: tap on map → address)
   - **Directions API** (for drawing the road route polyline and distance in taxi screens)
4. Go to **APIs & Services** → **Credentials** → **Create credentials** → **API key**.
5. (Recommended) Restrict the key:
   - **Android**: Application restrictions → Android apps → add package name `com.hudhud.userapp` and your debug/release SHA-1.
   - **iOS**: Application restrictions → iOS apps → add bundle ID `com.hudhud.userapp` (or your actual bundle ID from Xcode).
6. Copy the API key.

## 2. Store the key in .env (recommended)

1. Open (or create) **`android/local.properties`** in this project.  
   - Flutter/Android Studio often create it with `sdk.dir=...`. If the file doesn’t exist, create it.
2. Add (or update) this line with your key:
   ```properties
   GOOGLE_MAPS_API_KEY=your_actual_api_key_here
   ```
3. Do **not** commit `local.properties` (it is in `.gitignore`).  
   You can copy from **`android/local.properties.example`** and replace the placeholder.

4. Rebuild and run:
   ```bash
   flutter clean
   flutter run
   ```

## 3. iOS (if you build for iPhone/iPad)

**Option A – Environment variable (recommended)**  
- In Xcode: **Product** → **Scheme** → **Edit Scheme** → **Run** → **Arguments** → **Environment Variables** → add:
  - Name: `GOOGLE_MAPS_API_KEY`
  - Value: your API key  
- Or set the same variable in your CI when building.

**Option B – Info.plist (local only, do not commit)**  
- Open **`ios/Runner/Info.plist`** and set the value of `GoogleMapsAPIKey` to your key.  
- Do not commit this change; use Option A or CI for a clean repo.

Then rebuild and run on iOS.

## 4. If the map is still blank

- **Android**: Confirm `GOOGLE_MAPS_API_KEY` is set in **project root `.env`** or **`android/local.properties`**, then run `flutter clean` and `flutter run`.
- **iOS**: Confirm the key is set via the environment variable or in Info.plist and rebuild.
- In Cloud Console, ensure **Maps SDK for Android** (and **Maps SDK for iOS** for iOS) are **enabled** for your project.
- If the **route draws a straight line** instead of following roads: enable **Directions API** in Google Cloud Console (APIs & Services → Library → search “Directions API” → Enable). The same API key is used for route polylines.
- If you restricted the key, add your **debug SHA-1** so the key works in debug builds:
  - Run: `cd android && ./gradlew signingReport` (or open Android Studio → Gradle → app → signingReport) and copy the SHA-1 for the `debug` variant.
  - In Credentials → your API key → Application restrictions → Android apps → add `com.hudhud.userapp` with that SHA-1.
- Billing must be enabled on the Google Cloud project (Maps has a free tier; no charge until you exceed it).
- This project has **Impeller disabled** on Android in the manifest to avoid a known blank-map issue with `google_maps_flutter`. If you re-enable it, the map may go blank again on some devices.

For security (e.g. key rotation, not committing keys), see [SECURITY.md](SECURITY.md).
