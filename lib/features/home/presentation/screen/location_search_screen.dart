import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/app/services/custom_location_service.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/location_search_field.dart';

class LocationSearchScreen extends StatefulWidget {
  final String? currentLocation;

  const LocationSearchScreen({Key? key, this.currentLocation}) : super(key: key);

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Marker> _markers = {};

  LatLng _currentPosition = const LatLng(9.0222, 38.7468); // Default to Addis Ababa
  bool _isLoadingCurrentLocation = false;
  PlaceResult? _selectedPlace;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final position = await CustomLocationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _updateMarker(_currentPosition, isCurrentLocation: true);
          _mapController?.moveCamera(
            gmaps.CameraUpdate.newLatLngZoom(_toG(_currentPosition), 15.0),
          );
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.locationCurrentPositionFailed),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationCurrentPositionFailed),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
    }
  }

  void _updateMarker(LatLng position,
      {bool isCurrentLocation = false, PlaceResult? place}) {
    setState(() {
      _markers = {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pin'),
          position: _toG(position),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            isCurrentLocation
                ? gmaps.BitmapDescriptor.hueAzure
                : gmaps.BitmapDescriptor.hueRed,
          ),
        ),
      };
    });
  }

  void _handleMapTap(gmaps.LatLng point) async {
    setState(() {
      _markers = {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pin'),
          position: point,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
        ),
      };
    });

    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final places = await GooglePlacesService.reverseGeocode(
        point.latitude,
        point.longitude,
      );

      if (places.isNotEmpty) {
        setState(() {
          _selectedPlace = places.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.taxiCouldNotGetLocationDetails),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.locationSearchScreenTitle),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LocationSearchField(
              onLocationSelected: (place) {
                setState(() {
                  _selectedPlace = place;
                  _currentPosition = LatLng(
                    place.coordinates.latitude,
                    place.coordinates.longitude,
                  );
                  _updateMarker(_currentPosition, place: place);
                  _mapController?.moveCamera(
                    gmaps.CameraUpdate.newLatLngZoom(
                        _toG(_currentPosition), 15.0),
                  );
                });
              },
              initialLocation: widget.currentLocation,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                gmaps.GoogleMap(
                  initialCameraPosition: gmaps.CameraPosition(
                    target: _toG(_currentPosition),
                    zoom: 13.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: gmaps.MapType.normal,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _handleMapTap,
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'current_location',
                        mini: true,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        onPressed: _getCurrentLocation,
                        child: Icon(
                          Icons.my_location,
                          color: _isLoadingCurrentLocation
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_selectedPlace != null) ...[
            Material(
              color: colorScheme.surface,
              elevation: 8,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.locationSelectedHeading,
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ) ??
                          TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPlace!.shortAddress,
                              style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ) ??
                                  TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedPlace!.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ) ??
                                  TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.locationCoordinatesFormat(
                                _selectedPlace!.coordinates.latitude
                                    .toStringAsFixed(6),
                                _selectedPlace!.coordinates.longitude
                                    .toStringAsFixed(6),
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ) ??
                                  TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context, {
                            'address': _selectedPlace!.shortAddress,
                            'coordinates': _selectedPlace!.coordinates,
                          });
                        },
                        child: Text(
                          l10n.locationConfirmButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
