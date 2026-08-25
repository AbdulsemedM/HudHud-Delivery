import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/features/courier/data/models/nearby_drivers_result.dart';

const kDeliveryGuyMapAsset = 'assets/images/delivery-guy.png';

/// Decodes [kDeliveryGuyMapAsset] to a map marker ~[logicalWidth] dp wide.
Future<gmaps.BitmapDescriptor?> loadDeliveryGuyMapIcon({
  double logicalWidth = 56.0,
}) async {
  try {
    final data = await rootBundle.load(kDeliveryGuyMapAsset);
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

/// Generic vehicle markers only — no driver identity or contact actions.
Set<gmaps.Marker> nearbyDriverMapMarkers(
  List<NearbyDriverMarker> drivers, {
  gmaps.BitmapDescriptor? icon,
}) {
  final markerIcon = icon ??
      gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueOrange,
      );
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
        icon: markerIcon,
      ),
  };
}
