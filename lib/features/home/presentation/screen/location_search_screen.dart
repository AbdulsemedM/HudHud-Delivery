import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/app/services/custom_location_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/app/utils/human_readable_address.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/centered_pin_map.dart';
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

  /// Fallback only until GPS resolves (Addis Ababa).
  static const LatLng _fallbackPosition = LatLng(9.0222, 38.7468);

  LatLng _currentPosition = _fallbackPosition;
  bool _isLoadingCurrentLocation = false;
  bool _hasUserLocation = false;
  /// Bumps [CenteredPinMap] key so it remounts already centered on GPS.
  int _mapGeneration = 0;
  PlaceResult? _selectedPlace;

  /// Skip one idle geocode after programmatic camera moves.
  bool _skipNextIdleGeocode = false;

  /// Ignore idle reverse-geocode until the first GPS attempt finishes.
  bool _awaitingInitialGps = true;

  /// True after the user pans, taps, or picks a search result. Prevents a late
  /// GPS fix from overwriting their choice (and leaving address ≠ coords).
  bool _userChoseLocation = false;

  /// Monotonic id so stale [_getCurrentLocation] / GPS moves are ignored.
  int _gpsRequestId = 0;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  /// Keep PlaceResult.geometry aligned with the map pin we will confirm.
  PlaceResult _placeAtPin(PlaceResult place, LatLng pin) {
    return PlaceResult(
      displayName: place.displayName,
      coordinates: pin,
      street: place.street,
      neighborhood: place.neighborhood,
      sublocality: place.sublocality,
      establishment: place.establishment,
      city: place.city,
      state: place.state,
      country: place.country,
      postcode: place.postcode,
      isPlusCodeOnly: place.isPlusCodeOnly,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_getCurrentLocation());
    });
  }

  Future<void> _reverseGeocodeCenter(gmaps.LatLng point) async {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final pin = LatLng(point.latitude, point.longitude);

    try {
      final places = await GooglePlacesService.reverseGeocode(
        point.latitude,
        point.longitude,
      );

      if (!mounted) return;

      final best = HumanReadableAddress.pickBestPlace(places);
      if (best != null) {
        setState(() => _selectedPlace = _placeAtPin(best, pin));
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

  void _onCenterLatLngChanged(gmaps.LatLng point) {
    if (_skipNextIdleGeocode) {
      _skipNextIdleGeocode = false;
      return;
    }
    // Ignore the first idle while waiting for GPS so the Addis fallback
    // doesn't get reverse-geocoded / treated as a user choice.
    if (_awaitingInitialGps && !_userChoseLocation) return;

    // Camera idle is the source of truth for the center pin.
    _userChoseLocation = true;
    _gpsRequestId++; // cancel in-flight initial GPS snap-back
    final pin = LatLng(point.latitude, point.longitude);
    setState(() {
      _currentPosition = pin;
      _awaitingInitialGps = false;
      _isLoadingCurrentLocation = false;
    });
    unawaited(_reverseGeocodeCenter(point));
  }

  Future<void> _movePinTo(
    LatLng position, {
    bool reverseGeocode = true,
    bool remountMap = false,
  }) async {
    if (!mounted) return;

    setState(() {
      _currentPosition = position;
      _hasUserLocation = true;
      if (remountMap) {
        _mapGeneration++;
        _mapController = null;
      }
    });

    // Let the remounted map attach its controller.
    if (remountMap) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    final controller = _mapController;
    if (controller != null) {
      _skipNextIdleGeocode = true;
      try {
        await controller.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(_toG(position), 16.0),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('LocationSearchScreen: animateCamera failed: $e');
        }
      }
    }

    if (reverseGeocode && mounted) {
      await _reverseGeocodeCenter(_toG(position));
    }
  }

  Future<LocationFetchResult> _resolveGpsFix({bool forceFresh = false}) {
    return StartupLocationService.resolveFix(forceFresh: forceFresh);
  }

  void _showLocationFailureSnackBar(LocationFetchFailure? failure) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final showSettings = failure == LocationFetchFailure.permissionDenied ||
        failure == LocationFetchFailure.locationDisabled;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.locationCurrentPositionFailed),
        backgroundColor: colorScheme.error,
        action: showSettings
            ? SnackBarAction(
                label: l10n.actionOpenSettings,
                onPressed: CustomLocationService.openLocationAppSettings,
              )
            : null,
      ),
    );
  }

  Future<void> _getCurrentLocation({bool fromUserButton = false}) async {
    if (!mounted) return;

    if (fromUserButton) {
      // Explicit "my location" — allow GPS to move the pin again.
      _userChoseLocation = false;
    }

    final requestId = ++_gpsRequestId;

    setState(() {
      _isLoadingCurrentLocation = true;
      if (!fromUserButton) {
        _awaitingInitialGps = true;
      }
    });

    try {
      final gpsResult = await _resolveGpsFix(forceFresh: fromUserButton);
      if (!mounted || requestId != _gpsRequestId) return;

      // User already picked a place/pan while GPS was in flight — keep it.
      if (!fromUserButton && _userChoseLocation) {
        if (kDebugMode) {
          debugPrint(
            'LocationSearchScreen: ignoring late GPS; user already chose',
          );
        }
        return;
      }

      final position = gpsResult.data;
      if (position != null) {
        final latLng = LatLng(position.latitude, position.longitude);
        if (kDebugMode) {
          debugPrint(
            'LocationSearchScreen: GPS fix '
            '${latLng.latitude}, ${latLng.longitude}',
          );
        }
        await _movePinTo(latLng, remountMap: true);
      } else {
        _showLocationFailureSnackBar(gpsResult.failure);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocationSearchScreen: GPS error: $e');
      }
      if (mounted) {
        _showLocationFailureSnackBar(LocationFetchFailure.unknown);
      }
    } finally {
      if (mounted && requestId == _gpsRequestId) {
        setState(() {
          _isLoadingCurrentLocation = false;
          _awaitingInitialGps = false;
        });
      }
    }
  }

  Future<void> _handleMapTap(gmaps.LatLng point) async {
    _userChoseLocation = true;
    _skipNextIdleGeocode = true;
    final pin = LatLng(point.latitude, point.longitude);
    setState(() {
      _currentPosition = pin;
      _hasUserLocation = true;
    });
    await _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(point, 16.0),
    );
    await _reverseGeocodeCenter(point);
  }

  void _onMapCreated(gmaps.GoogleMapController controller) {
    _mapController = controller;
    if (_hasUserLocation) {
      // Ensure camera matches GPS if map remounted mid-fetch.
      unawaited(
        controller.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(_toG(_currentPosition), 16.0),
        ),
      );
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
                // Cancel any in-flight initial GPS so it can't snap back.
                _gpsRequestId++;
                _userChoseLocation = true;
                _awaitingInitialGps = false;
                final pin = LatLng(
                  place.coordinates.latitude,
                  place.coordinates.longitude,
                );
                setState(() {
                  _selectedPlace = _placeAtPin(place, pin);
                  _currentPosition = pin;
                  _hasUserLocation = true;
                  _isLoadingCurrentLocation = false;
                });
                _skipNextIdleGeocode = true;
                _mapController?.animateCamera(
                  gmaps.CameraUpdate.newLatLngZoom(
                    _toG(_currentPosition),
                    16.0,
                  ),
                );
              },
              initialLocation: widget.currentLocation,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                CenteredPinMap(
                  key: ValueKey('location_pin_map_$_mapGeneration'),
                  initialCameraPosition: gmaps.CameraPosition(
                    target: _toG(_currentPosition),
                    zoom: _hasUserLocation ? 16.0 : 13.0,
                  ),
                  idleDebounce: const Duration(milliseconds: 400),
                  onMapCreated: _onMapCreated,
                  onCenterLatLngChanged: _onCenterLatLngChanged,
                  onTap: _handleMapTap,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: gmaps.MapType.normal,
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    heroTag: 'current_location',
                    mini: true,
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    onPressed: _isLoadingCurrentLocation
                        ? null
                        : () => _getCurrentLocation(fromUserButton: true),
                    child: _isLoadingCurrentLocation
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.my_location,
                            color: colorScheme.primary,
                          ),
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
                              _selectedPlace!.formattedAddress,
                              style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ) ??
                                  TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_selectedPlace!.venueLabel
                                    .toLowerCase() !=
                                _selectedPlace!.formattedAddress
                                    .split(',')
                                    .first
                                    .trim()
                                    .toLowerCase()) ...[
                              const SizedBox(height: 8),
                              Text(
                                _selectedPlace!.venueLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ) ??
                                    TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              l10n.locationCoordinatesFormat(
                                _currentPosition.latitude
                                    .toStringAsFixed(6),
                                _currentPosition.longitude
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
                          // Pin center is authoritative — must match the address.
                          Navigator.pop(context, {
                            'address': _selectedPlace!.formattedAddress,
                            'coordinates': LatLng(
                              _currentPosition.latitude,
                              _currentPosition.longitude,
                            ),
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
