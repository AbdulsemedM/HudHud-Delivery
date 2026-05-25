import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/app/utils/human_readable_address.dart';
import 'package:hudhud_delivery/app/services/custom_location_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/core/widgets/centered_pin_map.dart';

class MapLocationScreen extends StatefulWidget {
  final String? currentLocation;

  const MapLocationScreen({Key? key, this.currentLocation}) : super(key: key);

  @override
  State<MapLocationScreen> createState() => _MapLocationScreenState();
}

class _MapLocationScreenState extends State<MapLocationScreen> {
  gmaps.GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// Device GPS fix only — no hardcoded city default.
  LatLng? _userPosition;
  bool _awaitingFirstLocation = true;
  String? _locationErrorMessage;
  // ignore: unused_field
  List<PlaceResult> _searchResults = [];
  Set<gmaps.Marker> _markers = {};
  bool _isSearching = false;
  bool _isLoadingCurrentLocation = false;
  bool? _hasGoogleMapsApiKey;
  // ignore: unused_field
  PlaceResult? _selectedPlace;

  /// From map camera center (debounced); user can confirm without tapping a search marker.
  PlaceResult? _centerPickPlace;

  /// After programmatic [moveCamera], skip the next idle geocode from [CenteredPinMap].
  bool _skipNextIdleGeocode = false;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  bool get _hasUserFix => _userPosition != null;

  @override
  void initState() {
    super.initState();
    final cached = StartupLocationService.cached;
    if (cached != null) {
      _userPosition = LatLng(cached.latitude, cached.longitude);
      _awaitingFirstLocation = false;
      _markers = _markersForSearch(_searchResults);
    }
    _loadMapsAvailability();
    _getCurrentLocation();
  }

  Future<void> _loadMapsAvailability() async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (!mounted) return;
    setState(() {
      _hasGoogleMapsApiKey = key.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final hadStartupFix = _userPosition != null;
    setState(() {
      _isLoadingCurrentLocation = !hadStartupFix;
      _locationErrorMessage = null;
    });

    try {
      await CustomLocationService.requestLocationPermission();
      if (!mounted) return;

      final LocationData? position =
          await CustomLocationService.getCurrentPosition();
      if (!mounted) return;
      if (position != null) {
        final newPosition = LatLng(position.latitude, position.longitude);
        setState(() {
          _awaitingFirstLocation = false;
          _userPosition = newPosition;
          _locationErrorMessage = null;
          _markers = _markersForSearch(_searchResults);
        });

        _skipNextIdleGeocode = true;
        _mapController?.moveCamera(
          gmaps.CameraUpdate.newLatLngZoom(_toG(newPosition), 15.0),
        );
      } else {
        setState(() {
          _awaitingFirstLocation = false;
          _userPosition = null;
          _markers = _markersForSearch(_searchResults);
          _locationErrorMessage =
              'Location unavailable. Enable Location in Settings and allow access for this app, then try again. You can also search for a place below.';
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        setState(() {
          _awaitingFirstLocation = false;
          _userPosition = null;
          _markers = _markersForSearch(_searchResults);
          _locationErrorMessage =
              'Could not read your position. Check Location permission in Settings, then try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
    }
  }

  Set<gmaps.Marker> _markersForSearch(List<PlaceResult> results) {
    return {
      ...results.map((place) => _createSearchMarker(place.coordinates, place)),
    };
  }

  /// Camera target for [GoogleMap]: real user fix, or first search result — never a hardcoded city.
  gmaps.LatLng _mapTarget() {
    if (_userPosition != null) return _toG(_userPosition!);
    assert(_searchResults.isNotEmpty);
    return _toG(_searchResults.first.coordinates);
  }

  double _mapZoom() {
    if (_userPosition != null) return 15.0;
    assert(_searchResults.isNotEmpty);
    return 12.0;
  }

  gmaps.Marker _createSearchMarker(LatLng position, PlaceResult place) {
    return gmaps.Marker(
      markerId: gmaps.MarkerId(place.shortAddress),
      position: _toG(position),
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
      infoWindow: gmaps.InfoWindow(title: place.shortAddress),
      onTap: () => _selectPlace(place),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (_hasGoogleMapsApiKey == false) return;
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _markers = _markersForSearch(_searchResults);
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await GooglePlacesService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _markers = _markersForSearch(results);
        });

        if (results.isNotEmpty) {
          final points = <LatLng>[
            if (_userPosition != null) _userPosition!,
            ...results.map((r) => r.coordinates),
          ];
          final bounds = _calculateBounds(points);
          _skipNextIdleGeocode = true;
          _mapController?.moveCamera(
            gmaps.CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      }
    } catch (e) {
      print('Error searching places: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  gmaps.LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat, minLng),
      northeast: gmaps.LatLng(maxLat, maxLng),
    );
  }

  void _selectPlace(PlaceResult place) {
    setState(() {
      _selectedPlace = place;
    });

    _skipNextIdleGeocode = true;
    _mapController?.moveCamera(
      gmaps.CameraUpdate.newLatLngZoom(_toG(place.coordinates), 16.0),
    );

    _showPlaceDetails(place);
  }

  Future<void> _onMapCenterChanged(gmaps.LatLng g) async {
    if (_skipNextIdleGeocode) {
      _skipNextIdleGeocode = false;
      return;
    }
    try {
      final places = await GooglePlacesService.reverseGeocode(
        g.latitude,
        g.longitude,
      );
      if (!mounted || places.isEmpty) return;
      final best = HumanReadableAddress.pickBestPlace(places);
      if (best == null) return;
      setState(() => _centerPickPlace = best);
    } catch (_) {
      // Non-fatal: user can still pick from search markers.
    }
  }

  Future<void> _onMapTap(gmaps.LatLng g) async {
    _searchFocusNode.unfocus();
    _skipNextIdleGeocode = true;
    await _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(g, 16.0),
    );
    try {
      final places = await GooglePlacesService.reverseGeocode(
        g.latitude,
        g.longitude,
      );
      if (!mounted || places.isEmpty) return;
      final best = HumanReadableAddress.pickBestPlace(places);
      if (best == null) return;
      setState(() => _centerPickPlace = best);
      _showPlaceDetails(best);
    } catch (_) {}
  }

  void _showPlaceDetails(PlaceResult place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.shortAddress,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.displayName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.orange),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmLocation(place),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Select Location',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _confirmLocation(PlaceResult place) {
    Navigator.pop(context);
    Navigator.pop(context, {
      'address': place.shortAddress,
      'latitude': place.coordinates.latitude,
      'longitude': place.coordinates.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoadingCurrentLocation)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
              tooltip: 'Refresh current location',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surface,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search for places...',
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colorScheme.onSurface.withOpacity(0.65),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _searchPlaces('');
                              _searchFocusNode.unfocus();
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchPlaces(value);
                  }
                });
              },
              onSubmitted: _searchPlaces,
            ),
          ),
          Expanded(
            child: _buildMapBody(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBody(ColorScheme colorScheme) {
    if (_hasGoogleMapsApiKey == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasGoogleMapsApiKey == false) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Google Maps is not configured on iOS yet. Add a Google Maps API key in iOS settings to use map selection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.75)),
          ),
        ),
      );
    }

    if (_awaitingFirstLocation) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Getting your location…',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.85)),
              ),
            ],
          ),
        ),
      );
    }

    final canShowMap = _hasUserFix || _searchResults.isNotEmpty;
    if (!canShowMap) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 48,
                color: colorScheme.onSurface.withOpacity(0.45),
              ),
              const SizedBox(height: 16),
              Text(
                _locationErrorMessage ??
                    'Turn on Location and allow access to show where you are on the map.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.85)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final target = _mapTarget();
    final zoom = _mapZoom();

    return Stack(
      fit: StackFit.expand,
      children: [
        CenteredPinMap(
          key: ValueKey<String>(
            '${_userPosition?.latitude},${_userPosition?.longitude},${_searchResults.length}',
          ),
          initialCameraPosition: gmaps.CameraPosition(
            target: target,
            zoom: zoom,
          ),
          markers: _markers,
          myLocationEnabled: _hasUserFix,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          idleDebounce: const Duration(milliseconds: 400),
          onCenterLatLngChanged: _onMapCenterChanged,
          onMapCreated: (controller) {
            _mapController = controller;
            if (_userPosition != null) {
              _skipNextIdleGeocode = true;
              controller.moveCamera(
                gmaps.CameraUpdate.newLatLngZoom(_toG(_userPosition!), 15.0),
              );
            }
          },
          onTap: _onMapTap,
        ),
        if (_centerPickPlace != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _centerPickPlace!.shortAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _confirmLocation(_centerPickPlace!),
                      child: const Text('Use pin'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
