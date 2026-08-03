# OTA updates (Shorebird + Firebase Remote Config)

This app uses **Shorebird** for Dart-only over-the-air patches and **Firebase Remote Config** as a safety net for store-required upgrades and an emergency patch kill switch.

## What can be patched vs what needs a store release

### Patchable with Shorebird (`shorebird patch`)

- Dart business logic and bug fixes
- Most UI / widget / navigation behavior written in Dart
- Dart-only dependency *code* already present in the release (you still cannot change `pubspec.yaml` versions via a patch)

### Store release required (`shorebird release` + Play / App Store)

- Native Android / iOS code changes
- Adding, removing, or upgrading plugins / `pubspec.yaml` dependency versions
- Permission or platform config changes (`AndroidManifest.xml`, `Info.plist`, Gradle, Pods, etc.)
- Anything Shorebird cannot hot-swap into an existing binary

Never attempt to force native / plugin / pubspec changes through a Shorebird patch.

## Runtime behavior

1. On app start (and on resume from background), the app silently calls Shorebird `checkForUpdate` / `update` when allowed.
2. Downloads never block the UI. Patches apply on the **next natural process restart** (user closes and reopens the app, OS kills the process, etc.). There is no mid-session force restart.
3. Offline / timeout / partial download failures fail open: the user can keep using the app; the check retries later.
4. Firebase Remote Config keys:
   - `minimum_supported_version` — if installed version is lower, show a **blocking** store update screen
   - `latest_store_version_android` — latest Play Store version (shown on Android force-update screen)
   - `latest_store_version_ios` — latest App Store version (shown on iOS force-update screen)
   - `kill_switch_patch_disabled` — when `true`, the app skips Shorebird check/download
   - `shorebird_update_track` — track name (`stable`, `staging`, `beta`, …) used by in-app checks

Configure these keys in the Firebase console for each environment. Defaults keep the app usable (`minimum_supported_version = 0.0.0`, both latest store versions `1.0.0`, kill switch off, track `stable`).

## CLI workflow

Use Shorebird for store binaries. Do **not** submit plain `flutter build` artifacts if you want patches to apply.

### Create a release (store binary)

```bash
# Android (.aab) — then upload to Play Console
shorebird release android

# iOS — requires macOS / Xcode; then archive / upload to App Store Connect
shorebird release ios
```

Bump `version:` in `pubspec.yaml` for each new store binary.

### Push a Dart patch against an existing release

The release version (e.g. `1.0.0+11`) must already exist in Shorebird and be what users installed.

```bash
shorebird patch android
shorebird patch ios

# Target an explicit release if needed
shorebird patch android --release-version=1.0.0+11
shorebird patch ios --release-version=1.0.0+11
```

### Local preview

```bash
shorebird preview
```

## Staged rollout (tracks)

Shorebird distributes patches per **track**. Default track is `stable`.

1. Publish a candidate patch to a non-production track:

   ```bash
   shorebird patch android --track=staging
   shorebird patch ios --track=staging
   ```

2. Point internal / QA devices at that track by setting Remote Config  
   `shorebird_update_track = staging` (or use accounts / install channels as described in Shorebird’s testing guide).

3. Verify on both Android and iOS, then publish the same fix to `stable` (or flip the track / promote per your process).

Percentage-based rollouts are implemented by combining tracks with your own cohort logic (see [Shorebird percentage-based rollouts](https://docs.shorebird.dev/code-push/guides/percentage-based-rollouts/)). Publish the canary patch to e.g. `--track=beta` and only put a percentage of devices onto that track.

## Emergency kill switch

If a bad patch reaches users:

1. Set Remote Config `kill_switch_patch_disabled = true` so clients stop downloading further patches.
2. Roll back / publish a fix patch on Shorebird (or ship a store release if needed).
3. Clear the kill switch when safe.

Note: a patch already downloaded and applied on next restart is not undone by the kill switch; use Shorebird console rollback / a corrective patch for that.

## Manual QA checklist

- [ ] Base release installed was built with `shorebird release` (not plain Flutter).
- [ ] Patch published to `staging` (or equivalent) first.
- [ ] Cold start on Android: patch downloads silently; UI is not blocked.
- [ ] Cold start on iOS: same.
- [ ] Kill app fully and reopen: patched code is active.
- [ ] Airplane mode on launch: app still opens; no crash; retries later.
- [ ] Interrupt download (toggle network mid-download): app remains usable; next launch retries.
- [ ] Set `kill_switch_patch_disabled = true`: no new download attempts (`[OTA]` logs show skip).
- [ ] Set `minimum_supported_version` above installed version: blocking store screen appears; cannot dismiss.
- [ ] Promote patch to `stable` only after staging sign-off.

## CI

GitHub Actions workflows:

- [`.github/workflows/shorebird-release.yml`](../.github/workflows/shorebird-release.yml) — tag `v*` or manual dispatch → `shorebird release`
- [`.github/workflows/shorebird-patch.yml`](../.github/workflows/shorebird-patch.yml) — tag `hotfix-*` or manual dispatch → `shorebird patch` for a given `--release-version`

Required secret: `SHOREBIRD_TOKEN` (Shorebird Console → Account → API Keys).

Patches require the target release version to already exist in Shorebird for that platform.

## Observability

Patch lifecycle events are logged with the `[OTA]` tag via `OtaLog` (check start/status, download start/complete, kill switch, timeouts, failures). Search device logs for `[OTA]` when validating releases.
