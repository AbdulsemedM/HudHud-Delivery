import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/features/courier/data/models/nearby_drivers_result.dart';

/// Generic vehicle markers only — no driver identity or contact actions.
Set<gmaps.Marker> nearbyDriverMapMarkers(List<NearbyDriverMarker> drivers) {
  return {
    for (final driver in drivers)
      gmaps.Marker(
        markerId: gmaps.MarkerId(driver.markerId),
        position: gmaps.LatLng(driver.latitude, driver.longitude),
        rotation: driver.heading ?? 0,
        flat: driver.heading != null,
        infoWindow: gmaps.InfoWindow(
          title: driver.label ?? 'Available ${driver.vehicleType ?? 'vehicle'}',
        ),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueOrange,
        ),
      ),
  };
}
