/// Play / App Store listing identifiers used by the forced-update screen.
class StoreConfig {
  StoreConfig._();

  /// Android applicationId (Play Store).
  static const String androidPackageId = 'com.hudhud.userapp';

  /// Numeric App Store ID. Leave empty until the listing exists; the launcher
  /// falls back to an App Store search for the display name.
  static const String iosAppStoreId = '';

  static const String appDisplayName = 'HudHud Delivery';
}
