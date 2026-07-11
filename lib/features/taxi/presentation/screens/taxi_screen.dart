import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/core/widgets/location_search_field.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/centered_pin_map.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/core/widgets/map_draggable_sheet_scaffold.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/app/utils/human_readable_address.dart';
import 'package:hudhud_delivery/features/taxi/data/ride_data_provider.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/features/guest/utils/guest_sign_in_prompt.dart';
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
  double _mapBottomPadding = 0;

  /// After programmatic camera moves, ignore one idle callback from [CenteredPinMap].
  bool _skipNextIdleDestinationUpdate = false;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _loadMapsAvailability();
    _getCurrentLocation();
    _loadSuggestedLocations();
    if (GuestBrowseService().isGuestBrowseMode) {
      _isCheckingActiveRide = false;
    } else {
      _checkActiveRide();
    }
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
          if (!GuestBrowseService().isGuestBrowseMode) {
            _fetchAvailableVehicles();
          }
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
    if (!await requireSignInForBackend(context)) {
      if (mounted) setState(() => _isCheckingActiveRide = false);
      return;
    }
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

  void _onTrackActiveRide() async {
    if (!await requireSignInForBackend(context)) return;
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
            rideId: _activeRide!['id'] as int?,
          ),
        ),
      ).then((_) => _checkActiveRide());
    }
  }

  Future<void> _fetchAvailableVehicles() async {
    if (GuestBrowseService().isGuestBrowseMode) return;
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
    // TODO: Implement schedule time picker
  }

  void _openDestinationSearch() {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppColors.r20),
            topRight: Radius.circular(AppColors.r20),
          ),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: AppColors.sp8),
              child: MapSheetDragHandle(),
            ),
            Padding(
              padding: const EdgeInsets.all(AppColors.sp16),
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
  }

  void _onBookPressed() {
    if (_destinationPosition != null &&
        _destinationController.text.trim().isNotEmpty) {
      _fetchRouteAndNavigate(_destinationController.text.trim());
      return;
    }
    _openDestinationSearch();
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

  void _onSheetLayoutChanged(double extent, double bodyHeight) {
    final padding = extent * bodyHeight;
    if ((padding - _mapBottomPadding).abs() > 1) {
      setState(() => _mapBottomPadding = padding);
    }
    if (_shouldShowActiveRideUI()) {
      _fitActiveRideBounds();
    }
  }

  void _fitActiveRideBounds() {
    final pickup = _activePickup;
    final dropoff = _activeDropoff;
    if (pickup == null || dropoff == null) return;

    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(
        pickup.latitude < dropoff.latitude
            ? pickup.latitude
            : dropoff.latitude,
        pickup.longitude < dropoff.longitude
            ? pickup.longitude
            : dropoff.longitude,
      ),
      northeast: gmaps.LatLng(
        pickup.latitude > dropoff.latitude
            ? pickup.latitude
            : dropoff.latitude,
        pickup.longitude > dropoff.longitude
            ? pickup.longitude
            : dropoff.longitude,
      ),
    );
    _mapController?.moveCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 50),
    );
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

    final overlayTop = mapOverlayTop(context, includeStatusBarInset: false);

    return MapDraggableSheetScaffold(
      backgroundColor: colorScheme.surface,
      initialChildSize: showActiveRide ? 0.45 : 0.35,
      minChildSize: 0.25,
      maxChildSize: 0.75,
      onSheetLayoutChanged: _onSheetLayoutChanged,
      map: _buildMapOrFallback(
        context,
        showActiveRide,
        activePickup,
        activeDropoff,
      ),
      mapOverlays: [
        if (!showActiveRide && _totalAvailable != null && _totalAvailable! > 0)
          Positioned(
            top: overlayTop + 48,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    Icon(Icons.local_taxi,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.taxiCarsNearby(_totalAvailable!),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (_estimatedWaitTime != null &&
                        _estimatedWaitTime! > 0) ...[
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
        Positioned(
          right: 16,
          top: overlayTop,
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
      ],
      sheetBuilder: (context, scrollController) {
        if (showActiveRide) {
          return _buildActiveRideSheet(context, scrollController);
        }
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppColors.r20),
              topRight: Radius.circular(AppColors.r20),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppColors.sp8),
                child: MapSheetDragHandle(),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.sp20,
                    AppColors.sp8,
                    AppColors.sp20,
                    AppColors.sp24,
                  ),
                  children: [
                    Text(
                      l10n.whereTo,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppColors.sp12),
                    if (_totalAvailable != null && _totalAvailable! > 0)
                      _TaxiDriversBubble(
                        count: _totalAvailable!,
                        waitMinutes: _estimatedWaitTime,
                      ),
                    if (_totalAvailable != null && _totalAvailable! > 0)
                      const SizedBox(height: AppColors.sp12),
                    _TaxiTimePillToggle(
                      timeChoice: _timeChoice,
                      onNowSelected: () {
                        setState(() => _timeChoice = _TaxiTimeChoice.now);
                      },
                      onScheduleSelected: () {
                        setState(
                          () => _timeChoice = _TaxiTimeChoice.scheduleLater,
                        );
                        _showTimePicker();
                      },
                    ),
                    const SizedBox(height: AppColors.sp12),
                    if (_destinationPosition != null &&
                        (_routeDistanceKm != null || _isLoadingRoute))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppColors.sp12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.straighten_rounded,
                              size: 18,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: AppColors.sp8),
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
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      onTap: _openDestinationSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppColors.sp16,
                          vertical: AppColors.sp12,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppColors.r16),
                          border: Border.all(
                            color: _destinationPosition != null
                                ? AppColors.primaryColor.withOpacity(0.35)
                                : colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconBox(
                              icon: Icons.search_rounded,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: AppColors.sp12),
                            Expanded(
                              child: Text(
                                _destinationController.text.isNotEmpty
                                    ? _destinationController.text
                                    : l10n.whereTo,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: _destinationController.text.isNotEmpty
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppColors.sp12),
                    ..._suggestedLocations.map(
                      (location) => _SuggestedLocationItem(
                        title: location.shortAddress,
                        address: location.displayName,
                        onTap: () => _selectSuggestedLocation(location),
                      ),
                    ),
                    const SizedBox(height: AppColors.sp16),
                    _TaxiBookButton(
                      enabled: _destinationPosition != null,
                      isLoading: _isLoadingRoute,
                      onPressed: _onBookPressed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      final overlayTop = mapOverlayTop(context, includeStatusBarInset: false);
      return gmaps.GoogleMap(
        padding: EdgeInsets.only(
          bottom: _mapBottomPadding,
          top: overlayTop + 48,
          left: 16,
          right: 16,
        ),
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
          _fitActiveRideBounds();
        },
      );
    }

    return CenteredPinMap(
      padding: EdgeInsets.only(bottom: _mapBottomPadding * 0.5),
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
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.r12),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppColors.sp8),
          padding: const EdgeInsets.all(AppColors.sp12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppColors.r12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBox(
                icon: Icons.history_rounded,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: AppColors.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppColors.sp4),
                    Text(
                      address,
                      style: theme.textTheme.bodySmall?.copyWith(
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
      ),
    );
  }
}

class _TaxiDriversBubble extends StatelessWidget {
  const _TaxiDriversBubble({
    required this.count,
    this.waitMinutes,
  });

  final int count;
  final int? waitMinutes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.sp12,
        vertical: AppColors.sp8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppColors.rFull),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_taxi_rounded,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: AppColors.sp8),
          Flexible(
            child: Text(
              l10n.taxiCarsNearby(count),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (waitMinutes != null && waitMinutes! > 0) ...[
            const SizedBox(width: AppColors.sp12),
            Icon(
              Icons.access_time_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppColors.sp4),
            Text(
              l10n.taxiMinutesWait(waitMinutes!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaxiTimePillToggle extends StatelessWidget {
  const _TaxiTimePillToggle({
    required this.timeChoice,
    required this.onNowSelected,
    required this.onScheduleSelected,
  });

  final _TaxiTimeChoice timeChoice;
  final VoidCallback onNowSelected;
  final VoidCallback onScheduleSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.all(AppColors.sp4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppColors.rFull),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TimePill(
              label: l10n.taxiTimeNow,
              icon: Icons.flash_on_rounded,
              selected: timeChoice == _TaxiTimeChoice.now,
              onTap: onNowSelected,
            ),
          ),
          Expanded(
            child: _TimePill(
              label: l10n.taxiScheduleForLater,
              icon: Icons.schedule_rounded,
              selected: timeChoice == _TaxiTimeChoice.scheduleLater,
              onTap: onScheduleSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.rFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.sp12,
            vertical: AppColors.sp8,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: AppColors.primaryGradient,
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.rFull),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppColors.sp8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxiBookButton extends StatelessWidget {
  const _TaxiBookButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final canTap = enabled && !isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canTap
              ? AppColors.primaryGradient
              : [AppColors.disabledButton, AppColors.disabledButton],
        ),
        borderRadius: BorderRadius.circular(AppColors.r16),
        boxShadow: canTap
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.r16),
          onTap: canTap ? onPressed : null,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.actionContinue,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

