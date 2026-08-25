import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

/// Full-screen map with a fixed center overlay pin. The selected point is the
/// map camera target — updated on [gmaps.GoogleMap.onCameraIdle] from the last
/// [gmaps.GoogleMap.onCameraMove] position.
///
/// Pass auxiliary [markers] / [polylines] (e.g. drivers, routes); do not add a
/// duplicate "selection" marker for the chosen place.
class CenteredPinMap extends StatefulWidget {
  const CenteredPinMap({
    super.key,
    required this.initialCameraPosition,
    required this.onMapCreated,
    this.onCenterLatLngChanged,
    this.onTap,
    this.markers = const {},
    this.polylines = const {},
    this.circles = const {},
    this.polygons = const {},
    this.padding = EdgeInsets.zero,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = false,
    this.mapType = gmaps.MapType.normal,
    this.zoomControlsEnabled = true,
    this.compassEnabled = true,
    this.mapToolbarEnabled = true,
    this.liteModeEnabled = false,
    this.tiltGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.indoorViewEnabled = true,
    this.cameraTargetBounds = gmaps.CameraTargetBounds.unbounded,
    this.minMaxZoomPreference = gmaps.MinMaxZoomPreference.unbounded,
    this.onCameraMoveStarted,
    this.centerIndicator,
    this.idleDebounce = Duration.zero,
  });

  final gmaps.CameraPosition initialCameraPosition;
  final void Function(gmaps.GoogleMapController controller) onMapCreated;
  final ValueChanged<gmaps.LatLng>? onCenterLatLngChanged;
  final void Function(gmaps.LatLng position)? onTap;
  final Set<gmaps.Marker> markers;
  final Set<gmaps.Polyline> polylines;
  final Set<gmaps.Circle> circles;
  final Set<gmaps.Polygon> polygons;
  final EdgeInsets padding;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final gmaps.MapType mapType;
  final bool zoomControlsEnabled;
  final bool compassEnabled;
  final bool mapToolbarEnabled;
  final bool liteModeEnabled;
  final bool tiltGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool indoorViewEnabled;
  final gmaps.CameraTargetBounds cameraTargetBounds;
  final gmaps.MinMaxZoomPreference minMaxZoomPreference;
  final VoidCallback? onCameraMoveStarted;

  /// Pin or custom widget; placed so the tip aligns with map center.
  final Widget? centerIndicator;

  /// If non-zero, [onCenterLatLngChanged] is fired after this delay from the
  /// last [onCameraIdle] (useful to batch with reverse geocode).
  final Duration idleDebounce;

  @override
  State<CenteredPinMap> createState() => _CenteredPinMapState();
}

class _CenteredPinMapState extends State<CenteredPinMap> {
  gmaps.CameraPosition? _lastCamera;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _emitCenter(gmaps.LatLng target) {
    void fire() {
      if (!mounted) return;
      widget.onCenterLatLngChanged?.call(target);
    }

    _debounceTimer?.cancel();
    if (widget.idleDebounce == Duration.zero) {
      fire();
    } else {
      _debounceTimer = Timer(widget.idleDebounce, fire);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final pin = widget.centerIndicator ??
        Icon(
          Icons.location_on,
          size: 48,
          color: primary,
          shadows: const [
            Shadow(
              blurRadius: 4,
              color: Colors.black26,
              offset: Offset(0, 2),
            ),
          ],
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        gmaps.GoogleMap(
          initialCameraPosition: widget.initialCameraPosition,
          padding: widget.padding,
          markers: widget.markers,
          polylines: widget.polylines,
          circles: widget.circles,
          polygons: widget.polygons,
          mapType: widget.mapType,
          myLocationEnabled: widget.myLocationEnabled,
          myLocationButtonEnabled: widget.myLocationButtonEnabled,
          zoomControlsEnabled: widget.zoomControlsEnabled,
          compassEnabled: widget.compassEnabled,
          mapToolbarEnabled: widget.mapToolbarEnabled,
          liteModeEnabled: widget.liteModeEnabled,
          tiltGesturesEnabled: widget.tiltGesturesEnabled,
          scrollGesturesEnabled: widget.scrollGesturesEnabled,
          zoomGesturesEnabled: widget.zoomGesturesEnabled,
          rotateGesturesEnabled: widget.rotateGesturesEnabled,
          indoorViewEnabled: widget.indoorViewEnabled,
          cameraTargetBounds: widget.cameraTargetBounds,
          minMaxZoomPreference: widget.minMaxZoomPreference,
          onMapCreated: widget.onMapCreated,
          onCameraMoveStarted: widget.onCameraMoveStarted,
          onCameraMove: (pos) => _lastCamera = pos,
          onCameraIdle: () {
            final t = _lastCamera?.target;
            if (t != null) {
              _emitCenter(t);
            }
          },
          onTap: widget.onTap,
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: pin,
            ),
          ),
        ),
      ],
    );
  }
}
