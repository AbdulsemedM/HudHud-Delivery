import 'custom_location_service.dart';

/// Resolves the device GPS fix and caches it for screens that need it.
class StartupLocationService {
  StartupLocationService._();

  static LocationData? _cached;
  static Future<LocationData?>? _fetchFuture;

  /// Set to true when the user has permanently denied location permission.
  static bool isPermanentlyDenied = false;

  /// Last successful fix (startup refresh or explicit update).
  static LocationData? get cached => _cached;

  /// Replace cache after a fresh read (e.g. app resume).
  static void updateCache(LocationData? data) {
    _cached = data;
  }

  /// Clears cache and fetches a new GPS fix — call on every cold start (splash).
  static Future<LocationData?> fetchFreshOnAppLaunch() async {
    _cached = null;
    _fetchFuture = null;
    isPermanentlyDenied = false;
    return _fetchOnce();
  }

  /// Returns cached fix or performs a single shared fetch (e.g. map screen).
  static Future<LocationData?> fetchAtStartup() {
    if (_cached != null) {
      return Future<LocationData?>.value(_cached);
    }
    _fetchFuture ??= _fetchOnce();
    return _fetchFuture!;
  }

  /// Resolves GPS for map screens. Set [forceFresh] to skip cache (e.g. "I am here").
  static Future<LocationFetchResult> resolveFix({bool forceFresh = false}) async {
    if (!forceFresh) {
      final cached = await fetchAtStartup();
      if (cached != null) {
        return LocationFetchResult.success(cached);
      }
    }

    isPermanentlyDenied =
        await CustomLocationService.isLocationPermissionPermanentlyDenied();
    if (isPermanentlyDenied) {
      return LocationFetchResult.failure(LocationFetchFailure.permissionDenied);
    }

    final granted = await CustomLocationService.requestLocationPermission();
    if (!granted) {
      isPermanentlyDenied =
          await CustomLocationService.isLocationPermissionPermanentlyDenied();
      return LocationFetchResult.failure(LocationFetchFailure.permissionDenied);
    }

    final result = await CustomLocationService.getCurrentPositionDetailed();
    if (result.data != null) {
      _cached = result.data;
    }
    return result;
  }

  static Future<LocationData?> _fetchOnce() async {
    try {
      final result = await resolveFix(forceFresh: true);
      return result.data;
    } catch (_) {
      return null;
    } finally {
      _fetchFuture = null;
    }
  }
}
