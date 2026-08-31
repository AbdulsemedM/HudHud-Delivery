import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/features/courier/data/models/nearby_drivers_result.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_vehicle_display.dart';

const kDeliveryGuyMapAsset = kCourierMotorbikeMapAsset;

/// In-memory cache of decoded map marker icons keyed by asset path.
class CourierVehicleMapIconCache {
  CourierVehicleMapIconCache._();

  static final Map<String, gmaps.BitmapDescriptor> _cache = {};

  static Map<String, gmaps.BitmapDescriptor> snapshot() =>
      Map<String, gmaps.BitmapDescriptor>.from(_cache);

  static gmaps.BitmapDescriptor? get(String assetPath) => _cache[assetPath];

  static Future<void> preloadAssets(Iterable<String> assetPaths) async {
    final missing = assetPaths
        .where((path) => path.isNotEmpty && !_cache.containsKey(path))
        .toSet();
    if (missing.isEmpty) return;

    await Future.wait(
      missing.map((path) async {
        final icon = await loadCourierVehicleMapIcon(assetPath: path);
        if (icon != null) {
          _cache[path] = icon;
        }
      }),
    );
  }
}

/// Preloads marker icons for the given API vehicle types (deduped by asset).
Future<void> preloadCourierVehicleMapIcons(
  Iterable<String?> vehicleTypes,
) async {
  final assets = vehicleTypes.map(courierVehicleMapAsset).toSet();
  await CourierVehicleMapIconCache.preloadAssets(assets);
}

/// Preloads the three common courier map marker assets.
Future<void> preloadCommonCourierVehicleMapIcons() async {
  await CourierVehicleMapIconCache.preloadAssets({
    kCourierMotorbikeMapAsset,
    kCourierTukMapAsset,
    kCourierCarMapAsset,
  });
}

/// Decodes a vehicle asset to a map marker ~[logicalWidth] dp wide.
Future<gmaps.BitmapDescriptor?> loadCourierVehicleMapIcon({
  required String assetPath,
  double logicalWidth = 56.0,
}) async {
  try {
    final data = await rootBundle.load(assetPath);
    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final targetWidth = (logicalWidth * dpr).round().clamp(72, 168);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final aspect = image.width / image.height;
    final logicalHeight = logicalWidth / aspect;
    return gmaps.BitmapDescriptor.fromBytes(
      byteData.buffer.asUint8List(),
      size: Size(logicalWidth, logicalHeight),
    );
  } catch (_) {
    return null;
  }
}

/// Decodes [kDeliveryGuyMapAsset] to a map marker ~[logicalWidth] dp wide.
Future<gmaps.BitmapDescriptor?> loadDeliveryGuyMapIcon({
  double logicalWidth = 56.0,
}) =>
    loadCourierVehicleMapIcon(
      assetPath: kDeliveryGuyMapAsset,
      logicalWidth: logicalWidth,
    );

gmaps.BitmapDescriptor _defaultNearbyMarkerIcon() =>
    gmaps.BitmapDescriptor.defaultMarkerWithHue(
      gmaps.BitmapDescriptor.hueOrange,
    );

/// Generic vehicle markers only — no driver identity or contact actions.
Set<gmaps.Marker> nearbyDriverMapMarkers(
  List<NearbyDriverMarker> drivers, {
  Map<String, gmaps.BitmapDescriptor>? iconsByAsset,
  gmaps.BitmapDescriptor? fallbackIcon,
}) {
  final defaultIcon = fallbackIcon ?? _defaultNearbyMarkerIcon();
  return {
    for (final driver in drivers)
      gmaps.Marker(
        markerId: gmaps.MarkerId(driver.markerId),
        position: gmaps.LatLng(driver.latitude, driver.longitude),
        rotation: driver.heading ?? 0,
        flat: driver.heading != null,
        anchor: const Offset(0.5, 0.5),
        infoWindow: gmaps.InfoWindow(
          title: driver.label ?? 'Available ${driver.vehicleType ?? 'vehicle'}',
        ),
        icon: iconsByAsset?[courierVehicleMapAsset(driver.vehicleType)] ??
            defaultIcon,
      ),
  };
}
