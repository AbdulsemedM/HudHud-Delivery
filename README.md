# hudhud_delivery

A new Flutter project.

## Google Maps

The app uses Google Maps for location and delivery features. **You must add a Google Maps API key** or the map will not load. See **[MAPS_SETUP.md](MAPS_SETUP.md)** for step-by-step setup (Android and iOS). For key security and rotation, see [SECURITY.md](SECURITY.md).

## OTA updates (Shorebird)

Dart-only bug fixes can be shipped over the air with Shorebird. Store-required / native changes still go through Play Store and App Store. See **[docs/ota-updates.md](docs/ota-updates.md)** for patch vs store rules, CLI commands, staged tracks, Remote Config keys, and QA checklist.

Quick commands:

```bash
shorebird release android   # store binary
shorebird release ios
shorebird patch android     # OTA Dart patch against an existing release
shorebird patch ios
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
