import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/core/widgets/location_search_field.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/core/widgets/centered_pin_map.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/app/utils/human_readable_address.dart';
import 'package:hudhud_delivery/features/taxi/data/ride_data_provider.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'finding_driver_screen.dart';
import 'driver_on_the_way_screen.dart';
import 'trip_selection_screen.dart';

enum _TaxiTimeChoice { now, scheduleLater }

class TaxiScreen extends StatefulWidget {
  const TaxiScreen({super.key});

  @override
  State<TaxiScreen> createState() => _TaxiScreenState();
}

class _AvailableDriver {
  final int id;
  final LatLng position;
  final String? vehicleType;
  final String? name;

  _AvailableDriver({
    required this.id,
    required this.position,
    this.vehicleType,
    this.name,
  });
}

class _TaxiScreenState extends State<TaxiScreen> {
  gmaps.GoogleMapController? _mapController;
  final TextEditingController _destinationController = TextEditingController();
  final RideDataProvider _rideDataProvider = RideDataProvider();
  LatLng _currentPosition = const LatLng(9.0222, 38.7468); // Default to Addis Ababa (same as location search)
  LatLng? _destinationPosition;
  bool _isLoadingLocation = true;
  List<PlaceResult> _suggestedLocations = [];
  _TaxiTimeChoice _timeChoice = _TaxiTimeChoice.now;
  List<_AvailableDriver> _availableDrivers = [];
  int? _totalAvailable;
  int? _estimatedWaitTime;
  Map<String, dynamic>? _activeRide;
  bool _isCheckingActiveRide = true;
  List<LatLng>? _routePolylinePoints;
  double? _routeDistanceKm;
  bool _isLoadingRoute = false;
  bool? _hasGoogleMapsApiKey;

  /// After programmatic camera moves, ignore one idle callback from [CenteredPinMap].
  bool _skipNextIdleDestinationUpdate = false;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _loadMapsAvailability();
    _getCurrentLocation();
    _loadSuggestedLocations();
    _checkActiveRide();
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
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final latLng = LatLng(position.latitude, position.longitude);

        if (mounted) {
          setState(() {
            _currentPosition = latLng;
            _isLoadingLocation = false;
          });

          _skipNextIdleDestinationUpdate = true;
          _mapController?.moveCamera(
            gmaps.CameraUpdate.newLatLngZoom(_toG(latLng), 13.0),
          );
          _fetchAvailableVehicles();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// Parses GET /api/user/rides/active body; returns null if no real active ride.
  Map<String, dynamic>? _parseActiveRidePayload(dynamic raw) {
    if (raw == null) return null;

    Map<String, dynamic>? ride;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      if (inner is Map) {
        ride = Map<String, dynamic>.from(inner);
      } else if (raw['ride'] is Map) {
        ride = Map<String, dynamic>.from(raw['ride'] as Map);
      } else if (raw.containsKey('id')) {
        ride = raw;
      }
    }

    if (ride == null) return null;

    final id = ride['id'];
    if (id == null || id.toString().isEmpty || id.toString() == '0') {
      return null;
    }

    final status = (ride['status'] as String? ?? '').toLowerCase();
    const terminal = {
      'completed',
      'cancelled',
      'canceled',
      'failed',
      'expired',
      'rejected',
    };
    if (terminal.contains(status)) return null;

    return ride;
  }

  bool _hasAssignedDriver(Map<String, dynamic> ride) {
    final driverId = ride['driver_id'];
    return driverId != null &&
        driverId.toString().isNotEmpty &&
        driverId.toString() != '0';
  }

  bool _isInProgressRideStatus(String status) {
    return {
      'accepted',
      'driver_arrived',
      'started',
      'in_progress',
      'arrived',
    }.contains(status);
  }

  /// Active ride sheet only when there is a real trip to track — not when
  /// searching with zero drivers nearby (show normal booking UI instead).
  bool _shouldShowActiveRideUI() {
    final ride = _activeRide;
    if (ride == null) return false;

    final status = (ride['status'] as String? ?? '').toLowerCase();
    if (_hasAssignedDriver(ride) || _isInProgressRideStatus(status)) {
      return true;
    }

    if (status == 'searching' && (_totalAvailable ?? 0) == 0) {
      return false;
    }

    return status == 'searching' && (_totalAvailable ?? 0) > 0;
  }

  void _reconcileActiveRideUI() {
    if (_activeRide != null && !_shouldShowActiveRideUI()) {
      _activeRide = null;
    }
  }

  Future<void> _checkActiveRide() async {
    final result = await _rideDataProvider.getActiveRide();

    if (!mounted) return;

    setState(() {
      _isCheckingActiveRide = false;
      if (result['statusCode'] == 200) {
        _activeRide = _parseActiveRidePayload(result['data']);
      } else {
        _activeRide = null;
      }
      _reconcileActiveRideUI();
    });

    if (_shouldShowActiveRideUI()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerMapOnActiveRide());
    }
  }

  void _centerMapOnActiveRide() {
    final pickupLat = double.tryParse(_activeRide!['pickup_latitude']?.toString() ?? '');
    final pickupLng = double.tryParse(_activeRide!['pickup_longitude']?.toString() ?? '');
    final dropoffLat = double.tryParse(_activeRide!['dropoff_latitude']?.toString() ?? '');
    final dropoffLng = double.tryParse(_activeRide!['dropoff_longitude']?.toString() ?? '');

    if (pickupLat != null && pickupLng != null && dropoffLat != null && dropoffLng != null) {
      final pickup = LatLng(pickupLat, pickupLng);
      final dropoff = LatLng(dropoffLat, dropoffLng);
      final bounds = gmaps.LatLngBounds(
        southwest: gmaps.LatLng(
          pickup.latitude < dropoff.latitude ? pickup.latitude : dropoff.latitude,
          pickup.longitude < dropoff.longitude ? pickup.longitude : dropoff.longitude,
        ),
        northeast: gmaps.LatLng(
          pickup.latitude > dropoff.latitude ? pickup.latitude : dropoff.latitude,
          pickup.longitude > dropoff.longitude ? pickup.longitude : dropoff.longitude,
        ),
      );
      _skipNextIdleDestinationUpdate = true;
      _mapController?.moveCamera(
        gmaps.CameraUpdate.newLatLngBounds(bounds, 80),
      );
    }
  }

  void _onTrackActiveRide() {
    if (!_shouldShowActiveRideUI()) return;

    final l10n = context.l10n;
    final pickupLat = double.tryParse(_activeRide!['pickup_latitude']?.toString() ?? '');
    final pickupLng = double.tryParse(_activeRide!['pickup_longitude']?.toString() ?? '');
    final dropoffLat = double.tryParse(_activeRide!['dropoff_latitude']?.toString() ?? '');
    final dropoffLng = double.tryParse(_activeRide!['dropoff_longitude']?.toString() ?? '');
    final pickupLocation = _activeRide!['pickup_location'] as String? ?? l10n.taxiPickup;
    final dropoffLocation = _activeRide!['dropoff_location'] as String? ?? l10n.taxiDestination;
    final status = _activeRide!['status'] as String? ?? 'searching';
    final vehicleType = _activeRide!['vehicle_type'] as String? ?? 'car';
    final rideType = _activeRide!['ride_type'] as String? ?? 'standard';
    final estimatedFare = (double.tryParse(_activeRide!['estimated_fare']?.toString() ?? '') ?? 0).round();
    final paymentMethod = _activeRide!['payment_method'] as String? ?? 'wallet';

    if (pickupLat == null || pickupLng == null || dropoffLat == null || dropoffLng == null) return;

    final pickup = LatLng(pickupLat, pickupLng);
    final dropoff = LatLng(dropoffLat, dropoffLng);
    final tripName =
        '${vehicleType[0].toUpperCase()}${vehicleType.substring(1)} ($rideType)';

    final hasDriver = _activeRide!['driver_id'] != null;
    if (status == 'searching' || !hasDriver) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindingDriverScreen(
            pickupLocation: pickup,
            destinationLocation: dropoff,
            pickupAddress: pickupLocation,
            destinationAddress: dropoffLocation,
            tripType: tripName,
            price: estimatedFare,
            paymentMethod: paymentMethod,
            rideId: _activeRide!['id'] as int?,
          ),
        ),
      ).then((_) => _checkActiveRide());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverOnTheWayScreen(
            pickupLocation: pickup,
            destinationLocation: dropoff,
            pickupAddress: pickupLocation,
            destinationAddress: dropoffLocation,
            tripType: tripName,
            price: estimatedFare,
            paymentMethod: paymentMethod,
          ),
        ),
      ).then((_) => _checkActiveRide());
    }
  }

  Future<void> _fetchAvailableVehicles() async {
    final result = await _rideDataProvider.getAvailableVehicles(
      latitude: _currentPosition.latitude,
      longitude: _currentPosition.longitude,
      vehicleType: 'car',
    );

    if (!mounted) return;

    if (result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      final drivers = <_AvailableDriver>[];
      final availableDriversList = data['availableDrivers'] as List<dynamic>? ?? [];

      for (final driver in availableDriversList) {
        final driverMap = driver as Map<String, dynamic>;
        final profile = driverMap['driver_profile'] as Map<String, dynamic>?;
        if (profile == null) continue;

        final latStr = profile['latitude']?.toString();
        final lngStr = profile['longitude']?.toString();
        if (latStr == null || lngStr == null) continue;

        final lat = double.tryParse(latStr);
        final lng = double.tryParse(lngStr);
        if (lat == null || lng == null) continue;

        drivers.add(_AvailableDriver(
          id: driverMap['id'] as int? ?? 0,
          position: LatLng(lat, lng),
          vehicleType: profile['vehicle_type'] as String?,
          name: driverMap['name'] as String?,
        ));
      }

      final totalRaw = data['total_available'];
      final total = totalRaw is int
          ? totalRaw
          : int.tryParse(totalRaw?.toString() ?? '');

      setState(() {
        _availableDrivers = drivers;
        _totalAvailable = total ?? 0;
        _estimatedWaitTime = data['estimated_wait_time'] as int?;
        _reconcileActiveRideUI();
      });
    }
  }

  Future<void> _loadSuggestedLocations() async {
    // Load some suggested locations (you can customize these)
    try {
      // Example: Search for popular locations
      final results = await GooglePlacesService.searchPlaces('Select Citywalk Mall');
      if (mounted && results.isNotEmpty) {
        setState(() {
          _suggestedLocations = results.take(2).toList();
        });
      }
    } catch (e) {
      // Fallback to hardcoded suggestions
      setState(() {
        _suggestedLocations = [
          PlaceResult(
            displayName: 'Saket Disctrict Center, District Center, Sector 6, Pushp Vihar, New Delhi, Delhi 110017',
            coordinates: const LatLng(28.5355, 77.2190),
            street: 'Select Citywalk Mall',
            city: 'New Delhi',
            country: 'India',
          ),
          PlaceResult(
            displayName: 'New Manglapuri, Manglapuri Village, Sultanpur, New Delhi, Delhi',
            coordinates: const LatLng(28.5000, 77.2000),
            street: '5, Kullar Farms Rd',
            city: 'New Delhi',
            country: 'India',
          ),
        ];
      });
    }
  }

  void _onLocationSelected(PlaceResult place) {
    _skipNextIdleDestinationUpdate = true;
    setState(() {
      _destinationPosition = place.coordinates;
      _destinationController.text = place.shortAddress;
      _routePolylinePoints = null;
      _routeDistanceKm = null;
      _isLoadingRoute = true;
    });
    _fetchRouteAndNavigate(place.shortAddress);
  }

  Future<void> _onDestinationCenterChanged(gmaps.LatLng g) async {
    if (_skipNextIdleDestinationUpdate) {
      _skipNextIdleDestinationUpdate = false;
      return;
    }
    final latLng = LatLng(g.latitude, g.longitude);
    if (_calculateDistance(_currentPosition, latLng) < 100) {
      return;
    }

    try {
      final places = await GooglePlacesService.reverseGeocode(
        g.latitude,
        g.longitude,
      );

      if (!mounted || places.isEmpty) return;

      final place = HumanReadableAddress.pickBestPlace(places);
      if (place == null) return;
      setState(() {
        _destinationPosition = latLng;
        _destinationController.text = place.shortAddress;
        _routePolylinePoints = null;
        _routeDistanceKm = null;
        _isLoadingRoute = true;
      });

      await _fetchRouteDirections();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.taxiErrorWithDetails(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _fetchRouteAndNavigate(String destinationAddress) async {
    await _fetchRouteDirections();
    if (!mounted || _destinationPosition == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripSelectionScreen(
          pickupLocation: _currentPosition,
          destinationLocation: _destinationPosition!,
          pickupAddress: context.l10n.taxiCurrentLocation,
          destinationAddress: destinationAddress,
          initialRouteDistanceKm: _routeDistanceKm,
          initialRoutePolylinePoints: _routePolylinePoints,
        ),
      ),
    );
  }

  Future<void> _fetchRouteDirections() async {
    if (_destinationPosition == null) return;
    final result = await GoogleDirectionsService.getDirections(
      originLat: _currentPosition.latitude,
      originLng: _currentPosition.longitude,
      destLat: _destinationPosition!.latitude,
      destLng: _destinationPosition!.longitude,
    );
    if (!mounted) return;
    setState(() {
      _isLoadingRoute = false;
      if (result != null) {
        _routePolylinePoints = result.polylinePoints;
        _routeDistanceKm = result.distanceKm;
      }
    });
  }

  void _selectSuggestedLocation(PlaceResult place) {
    _onLocationSelected(place);
  }

  Future<void> _handleMapTap(gmaps.LatLng point) async {
    final latLng = LatLng(point.latitude, point.longitude);
    final distance = _calculateDistance(_currentPosition, latLng);
    if (distance < 100) {
      return;
    }

    _skipNextIdleDestinationUpdate = true;
    await _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(point, 15.0),
    );

    // Show loading indicator
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Reverse geocode the tapped location
      final places = await GooglePlacesService.reverseGeocode(
        point.latitude,
        point.longitude,
      );

      if (mounted && places.isNotEmpty) {
        final place = HumanReadableAddress.pickBestPlace(places);
        if (place == null) return;
        setState(() {
          _destinationPosition = latLng;
          _destinationController.text = place.shortAddress;
          _isLoadingLocation = false;
          _routePolylinePoints = null;
          _routeDistanceKm = null;
          _isLoadingRoute = true;
        });

        await _fetchRouteAndNavigate(place.shortAddress);
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.taxiCouldNotGetLocationDetails),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.taxiErrorWithDetails(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Simple distance calculation using Haversine formula
    const double earthRadius = 6371000; // meters
    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLat = (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLng = (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  void _showTimePicker() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.access_time, color: primary),
              title: Text(l10n.taxiTimeNow),
              onTap: () {
                setState(() {
                  _timeChoice = _TaxiTimeChoice.now;
                });
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: primary),
              title: Text(l10n.taxiScheduleForLater),
              onTap: () {
                setState(() {
                  _timeChoice = _TaxiTimeChoice.scheduleLater;
                });
                // TODO: Implement time picker
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  LatLng? get _activePickup {
    if (_activeRide == null) return null;
    final lat = double.tryParse(_activeRide!['pickup_latitude']?.toString() ?? '');
    final lng = double.tryParse(_activeRide!['pickup_longitude']?.toString() ?? '');
    return (lat != null && lng != null) ? LatLng(lat, lng) : null;
  }

  LatLng? get _activeDropoff {
    if (_activeRide == null) return null;
    final lat = double.tryParse(_activeRide!['dropoff_latitude']?.toString() ?? '');
    final lng = double.tryParse(_activeRide!['dropoff_longitude']?.toString() ?? '');
    return (lat != null && lng != null) ? LatLng(lat, lng) : null;
  }

  String _activeRideStatusLabel(AppLocalizations l10n) {
    final status = _activeRide?['status'] as String? ?? '';
    switch (status) {
      case 'searching':
        return l10n.taxiStatusFindingDriver;
      case 'accepted':
        return l10n.taxiStatusDriverOnTheWay;
      case 'driver_arrived':
        return l10n.taxiStatusDriverArrived;
      case 'started':
        return l10n.taxiStatusTripInProgress;
      default:
        return status.isNotEmpty
            ? status.replaceAll('_', ' ')
            : l10n.taxiStatusActiveRide;
    }
  }

  Widget _buildActiveRideSheet(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final pickupLocation = _activeRide!['pickup_location'] as String? ?? l10n.taxiPickup;
    final dropoffLocation = _activeRide!['dropoff_location'] as String? ?? l10n.taxiDestination;
    final estimatedFare = _activeRide!['estimated_fare']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_taxi, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.taxiActiveRide,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _activeRideStatusLabel(l10n),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationRow(
                  context,
                  Icons.trip_origin,
                  pickupLocation,
                  colorScheme.primary,
                ),
                const SizedBox(height: 10),
                _buildLocationRow(
                  context,
                  Icons.location_on,
                  dropoffLocation,
                  colorScheme.error,
                ),
                if (estimatedFare != null && estimatedFare != 'null') ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.taxiEstFare,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          l10n.taxiFareAmount(
                            double.tryParse(estimatedFare)
                                    ?.toStringAsFixed(2) ??
                                estimatedFare,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _onTrackActiveRide,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.taxiTrackRide,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isCheckingActiveRide
                  ? null
                  : () {
                      setState(() => _isCheckingActiveRide = true);
                      _checkActiveRide();
                    },
              child: _isCheckingActiveRide
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Text(
                      l10n.taxiRefreshStatus,
                      style:
                          TextStyle(color: colorScheme.primary, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context,
    IconData icon,
    String text,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ) ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Set<gmaps.Marker> _buildTaxiMarkers(
    bool hasActiveRide,
    LatLng? activePickup,
    LatLng? activeDropoff,
  ) {
    final Set<gmaps.Marker> markers = {};
    if (hasActiveRide && activePickup != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: _toG(activePickup),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    if (hasActiveRide && activeDropoff != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('dropoff'),
          position: _toG(activeDropoff),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
        ),
      );
    }
    if (!hasActiveRide) {
      for (var i = 0; i < _availableDrivers.length; i++) {
        final driver = _availableDrivers[i];
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('driver_$i'),
            position: _toG(driver.position),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueOrange,
            ),
          ),
        );
      }
    }
    return markers;
  }

  Set<gmaps.Polyline> _buildTaxiPolylines(
    bool hasActiveRide,
    LatLng? activePickup,
    LatLng? activeDropoff,
    Color routeColor,
  ) {
    final Set<gmaps.Polyline> polylines = {};
    if (_destinationPosition != null && !hasActiveRide) {
      final points = _routePolylinePoints != null && _routePolylinePoints!.length >= 2
          ? _routePolylinePoints!.map(_toG).toList()
          : [_toG(_currentPosition), _toG(_destinationPosition!)];
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          points: points,
          color: routeColor,
          width: 3,
        ),
      );
    }
    if (hasActiveRide && activePickup != null && activeDropoff != null) {
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('active_route'),
          points: [_toG(activePickup), _toG(activeDropoff)],
          color: routeColor,
          width: 3,
        ),
      );
    }
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final showActiveRide = _shouldShowActiveRideUI();
    final activePickup = showActiveRide ? _activePickup : null;
    final activeDropoff = showActiveRide ? _activeDropoff : null;

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetInitialFraction = showActiveRide ? 0.45 : 0.35;
    final mapBottom = screenHeight * bottomSheetInitialFraction;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: mapBottom,
            child: _buildMapOrFallback(
              context,
              showActiveRide,
              activePickup,
              activeDropoff,
            ),
          ),
          // Available cars info chip - hide when active ride
          if (!showActiveRide && _totalAvailable != null && _totalAvailable! > 0)
            Positioned(
              top: 95,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_taxi, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.taxiCarsNearby(_totalAvailable!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (_estimatedWaitTime != null && _estimatedWaitTime! > 0) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.taxiMinutesWait(_estimatedWaitTime!),
                          style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ) ??
                              TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          // Current location button
          Positioned(
            right: 16,
            top: 100,
            child: FloatingActionButton(
              heroTag: 'current_location',
              mini: true,
              backgroundColor: colorScheme.surfaceContainerHigh,
              onPressed: () async {
                await _getCurrentLocation();
                _fetchAvailableVehicles();
              },
              child: Icon(
                Icons.my_location,
                color: _isLoadingLocation
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
              ),
            ),
          ),
          // Bottom Sheet Modal
          DraggableScrollableSheet(
            initialChildSize: showActiveRide ? 0.45 : 0.35,
            minChildSize: 0.25,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              if (showActiveRide) {
                return _buildActiveRideSheet(context, scrollController);
              }
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.taxiBrandHudHud,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            l10n.taxiBrandDelivery,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Distance in KM when destination is set
                    if (_destinationPosition != null &&
                        (_routeDistanceKm != null || _isLoadingRoute))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.straighten,
                                size: 18, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            if (_isLoadingRoute)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_routeDistanceKm != null)
                              Text(
                                l10n.taxiDistanceKm(
                                  _routeDistanceKm!.toStringAsFixed(2),
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (_destinationPosition != null &&
                        (_routeDistanceKm != null || _isLoadingRoute))
                      const SizedBox(height: 12),
                    // Search Bar and Now Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Search Bar
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _destinationController,
                                style: TextStyle(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: l10n.whereTo,
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: colorScheme.primary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onTap: () {
                                  // Show location search
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (sheetContext) => Container(
                                      height:
                                          MediaQuery.of(sheetContext).size.height *
                                              0.7,
                                      decoration: BoxDecoration(
                                        color: Theme.of(sheetContext)
                                            .colorScheme
                                            .surface,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: LocationSearchField(
                                              hintText: l10n.whereTo,
                                              onLocationSelected: (place) {
                                                _onLocationSelected(place);
                                                Navigator.pop(sheetContext);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Now Button
                          GestureDetector(
                            onTap: _showTimePicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _timeChoice == _TaxiTimeChoice.now
                                        ? l10n.taxiTimeNow
                                        : l10n.taxiScheduleForLater,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Suggested Locations
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _suggestedLocations.length,
                        itemBuilder: (context, index) {
                          final location = _suggestedLocations[index];
                          return _SuggestedLocationItem(
                            title: location.shortAddress,
                            address: location.displayName,
                            onTap: () => _selectSuggestedLocation(location),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapOrFallback(
    BuildContext context,
    bool hasActiveRide,
    LatLng? activePickup,
    LatLng? activeDropoff,
  ) {
    if (_hasGoogleMapsApiKey == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasGoogleMapsApiKey == false) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.taxiGoogleMapsNotConfigured,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    if (hasActiveRide) {
      return gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: _toG(_currentPosition),
          zoom: 13.0,
        ),
        markers: _buildTaxiMarkers(hasActiveRide, activePickup, activeDropoff),
        polylines: _buildTaxiPolylines(
          hasActiveRide,
          activePickup,
          activeDropoff,
          Theme.of(context).colorScheme.primary,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        mapType: gmaps.MapType.normal,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      );
    }

    return CenteredPinMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _toG(_currentPosition),
        zoom: 13.0,
      ),
      idleDebounce: const Duration(milliseconds: 400),
      onCenterLatLngChanged: _onDestinationCenterChanged,
      markers: _buildTaxiMarkers(hasActiveRide, activePickup, activeDropoff),
      polylines: _buildTaxiPolylines(
        hasActiveRide,
        activePickup,
        activeDropoff,
        Theme.of(context).colorScheme.primary,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: gmaps.MapType.normal,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onTap: _handleMapTap,
    );
  }
}

class _SuggestedLocationItem extends StatelessWidget {
  final String title;
  final String address;
  final VoidCallback onTap;

  const _SuggestedLocationItem({
    required this.title,
    required this.address,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.access_time,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ) ??
                        TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

