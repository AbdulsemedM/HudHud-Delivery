import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/core/widgets/location_search_field.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/features/taxi/data/ride_data_provider.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'finding_driver_screen.dart';
import 'driver_on_the_way_screen.dart';
import 'trip_selection_screen.dart';

enum _TaxiTimeChoice { now, scheduleLater }

/// Gold accent for taxi chrome under the always-dark Home hub.
const Color _taxiGold = ServiceTabPalette.taxi;

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
  bool _isCancellingRide = false;
  List<LatLng>? _routePolylinePoints;
  double? _routeDistanceKm;
  bool _isLoadingRoute = false;
  bool? _hasGoogleMapsApiKey;

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

  Future<void> _checkActiveRide() async {
    final result = await _rideDataProvider.getActiveRide();

    if (!mounted) return;

    setState(() {
      _isCheckingActiveRide = false;
      if (result['statusCode'] == 200 && result['data'] != null) {
        _activeRide = result['data'] as Map<String, dynamic>;
      } else {
        _activeRide = null;
        _routePolylinePoints = null;
        _routeDistanceKm = null;
      }
    });

    if (_activeRide != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOnActiveRide();
        _fetchActiveRideRouteDirections();
      });
    }
  }

  /// Road-following polyline for the active ride (pickup → dropoff).
  Future<void> _fetchActiveRideRouteDirections() async {
    final pickup = _activePickup;
    final dropoff = _activeDropoff;
    if (pickup == null || dropoff == null) return;

    // Skip if we already have a road route for roughly the same endpoints.
    if (_routePolylinePoints != null && _routePolylinePoints!.length >= 2) {
      final first = _routePolylinePoints!.first;
      final last = _routePolylinePoints!.last;
      final sameStart = _calculateDistance(first, pickup) < 80; // meters
      final sameEnd = _calculateDistance(last, dropoff) < 80;
      if (sameStart && sameEnd) return;
    }

    final result = await GoogleDirectionsService.getDirections(
      originLat: pickup.latitude,
      originLng: pickup.longitude,
      destLat: dropoff.latitude,
      destLng: dropoff.longitude,
    );
    if (!mounted || _activeRide == null) return;
    setState(() {
      if (result != null) {
        _routePolylinePoints = result.polylinePoints;
        _routeDistanceKm = result.distanceKm;
      }
    });
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
      _mapController?.moveCamera(
        gmaps.CameraUpdate.newLatLngBounds(bounds, 80),
      );
    }
  }

  int? _activeRideId() {
    final id = _activeRide?['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  bool get _canCancelActiveRide {
    if (_activeRide == null) return false;
    final status = _activeRide!['status'] as String? ?? 'searching';
    final hasDriver = _activeRide!['driver_id'] != null;
    return status == 'searching' || !hasDriver;
  }

  Future<void> _cancelActiveRide() async {
    final l10n = context.l10n;
    final rideId = _activeRideId();
    if (rideId == null || _isCancellingRide) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
        ),
        title: const Text('Cancel Trip'),
        content: const Text('Are you sure you want to cancel this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: Text(l10n.actionYesCancel),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isCancellingRide = true);
    final result = await _rideDataProvider.cancelRide(rideId: rideId);
    if (!mounted) return;
    setState(() => _isCancellingRide = false);

    final statusCode = result['statusCode'] as int?;
    final success = statusCode != null && statusCode >= 200 && statusCode < 300;
    if (success) {
      setState(() {
        _activeRide = null;
        _routePolylinePoints = null;
        _routeDistanceKm = null;
      });
      final message = (result['data'] is Map)
          ? (result['data'] as Map)['message']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Ride cancelled successfully.'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['errorMessage']?.toString() ?? 'Failed to cancel ride',
          ),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _onTrackActiveRide() {
    if (_activeRide == null) return;

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
            rideId: _activeRideId(),
          ),
        ),
      ).then((_) => _checkActiveRide());
    } else {
      final driver = _activeRide!['driver'];
      final driverName = driver is Map
          ? (driver['name']?.toString() ?? 'Driver')
          : (_activeRide!['driver_name']?.toString() ?? 'Driver');
      final driverPhone = driver is Map
          ? driver['phone']?.toString()
          : _activeRide!['driver_phone']?.toString();

      LatLng? driverPosition;
      LatLng? fromCoords(dynamic lat, dynamic lng) {
        final latitude = double.tryParse(lat?.toString() ?? '');
        final longitude = double.tryParse(lng?.toString() ?? '');
        if (latitude == null || longitude == null) return null;
        return LatLng(latitude, longitude);
      }

      driverPosition = fromCoords(
        _activeRide!['current_latitude'] ?? _activeRide!['driver_latitude'],
        _activeRide!['current_longitude'] ?? _activeRide!['driver_longitude'],
      );
      if (driverPosition == null && driver is Map) {
        driverPosition = fromCoords(
          driver['latitude'] ?? driver['lat'] ?? driver['current_latitude'],
          driver['longitude'] ?? driver['lng'] ?? driver['current_longitude'],
        );
      }

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
            rideId: _activeRideId(),
            driverName: driverName,
            driverPhone: driverPhone,
            driverPosition: driverPosition,
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

      setState(() {
        _availableDrivers = drivers;
        _totalAvailable = data['total_available'] as int?;
        _estimatedWaitTime = data['estimated_wait_time'] as int?;
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
      if (mounted) {
        setState(() {
          _suggestedLocations = [];
        });
      }
    }
  }

  void _onLocationSelected(PlaceResult place) {
    setState(() {
      _destinationPosition = place.coordinates;
      _destinationController.text = place.shortAddress;
      _routePolylinePoints = null;
      _routeDistanceKm = null;
      _isLoadingRoute = true;
    });
    _fetchRouteAndNavigate(place.shortAddress);
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
    // Don't set destination if user tapped on their current location
    final distance = _calculateDistance(_currentPosition, latLng);
    if (distance < 0.001) {
      // Less than 100 meters, probably the same location
      return;
    }

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
        final place = places.first;
        setState(() {
          _destinationPosition = latLng;
          _destinationController.text = place.shortAddress;
          _isLoadingLocation = false;
          _routePolylinePoints = null;
          _routeDistanceKm = null;
          _isLoadingRoute = true;
        });

        // Move map to show the destination
        _mapController?.moveCamera(
          gmaps.CameraUpdate.newLatLngZoom(point, 15.0),
        );

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
              leading: const Icon(Icons.access_time, color: _taxiGold),
              title: Text(l10n.taxiTimeNow),
              onTap: () {
                setState(() {
                  _timeChoice = _TaxiTimeChoice.now;
                });
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: _taxiGold),
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

  Color _cardBorder(BuildContext context) {
    return HomeColors.border;
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

    final borderColor = _cardBorder(context);

    return Container(
      decoration: BoxDecoration(
        color: HomeColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppColors.radiusXL),
          topRight: Radius.circular(AppColors.radiusXL),
        ),
        border: Border(
          top: BorderSide(color: borderColor),
          left: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
        ),
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_taxi, color: _taxiGold, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.taxiActiveRide,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _taxiGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spaceSM),
          Center(
            child: StatusChip(
              status: _activeRide?['status'] as String? ?? 'active',
            ),
          ),
          const SizedBox(height: AppColors.spaceMD),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
            padding: const EdgeInsets.all(AppColors.spaceMD),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationRow(
                  context,
                  Icons.trip_origin_rounded,
                  pickupLocation,
                  AppColors.successColor,
                ),
                const SizedBox(height: AppColors.spaceMD),
                _buildLocationRow(
                  context,
                  Icons.location_on_rounded,
                  dropoffLocation,
                  AppColors.errorColor,
                ),
                if (estimatedFare != null && estimatedFare != 'null') ...[
                  const SizedBox(height: AppColors.spaceMD),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: AppColors.spaceMD),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.taxiEstFare,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        l10n.taxiFareAmount(
                          double.tryParse(estimatedFare)?.toStringAsFixed(2) ??
                              estimatedFare,
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _taxiGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppColors.spaceLG),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
            child: SizedBox(
              width: double.infinity,
              height: AppColors.buttonHeightMD,
              child: FilledButton(
                onPressed: _isCancellingRide ? null : _onTrackActiveRide,
                style: FilledButton.styleFrom(
                  backgroundColor: _taxiGold,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusLG),
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
          if (_canCancelActiveRide) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
              child: SizedBox(
                width: double.infinity,
                height: AppColors.buttonHeightMD,
                child: OutlinedButton(
                  onPressed: _isCancellingRide ? null : _cancelActiveRide,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorColor,
                    side: BorderSide(
                      color: AppColors.errorColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                  child: _isCancellingRide
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.errorColor,
                          ),
                        )
                      : Text(
                          l10n.actionCancel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: (_isCheckingActiveRide || _isCancellingRide)
                  ? null
                  : () {
                      setState(() => _isCheckingActiveRide = true);
                      _checkActiveRide();
                    },
              child: _isCheckingActiveRide
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _taxiGold,
                      ),
                    )
                  : Text(
                      l10n.taxiRefreshStatus,
                      style: const TextStyle(color: _taxiGold, fontSize: 14),
                    ),
            ),
          ),
          const SizedBox(height: 16),
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
    if (!hasActiveRide) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('current'),
          position: _toG(_currentPosition),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
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
    if (_destinationPosition != null && !hasActiveRide) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('destination'),
          position: _toG(_destinationPosition!),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
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
          color: _taxiGold,
          width: 3,
        ),
      );
    }
    if (hasActiveRide && activePickup != null && activeDropoff != null) {
      final points =
          _routePolylinePoints != null && _routePolylinePoints!.length >= 2
              ? _routePolylinePoints!.map(_toG).toList()
              : [_toG(activePickup), _toG(activeDropoff)];
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('active_route'),
          points: points,
          color: _taxiGold,
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
    final hasActiveRide = _activeRide != null;
    final activePickup = _activePickup;
    final activeDropoff = _activeDropoff;

    final borderColor = _cardBorder(context);

    return Scaffold(
      backgroundColor: HomeColors.background,
      // Nested under Home — no AppBar (avoids double chrome).
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use this body's height (not full screen) so the sheet/map
          // leave no black gap when Taxi is embedded under Home.
          final sheetInitial = hasActiveRide ? 0.45 : 0.38;
          return Stack(
            children: [
              // Full-bleed map; sheet floats on top (covers bottom).
              Positioned.fill(
                child: _buildMapOrFallback(
                  context,
                  hasActiveRide,
                  activePickup,
                  activeDropoff,
                ),
              ),
              // Available cars info chip - hide when active ride
              if (!hasActiveRide &&
                  _totalAvailable != null &&
                  _totalAvailable! > 0)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 56,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.spaceMD,
                        vertical: AppColors.spaceSM,
                      ),
                      decoration: BoxDecoration(
                        color: HomeColors.surfaceElevated,
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusFull),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_taxi,
                              color: _taxiGold, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.taxiCarsNearby(_totalAvailable!),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
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
              // Current location button
              Positioned(
                right: 16,
                top: 8,
                child: FloatingActionButton(
                  heroTag: 'current_location',
                  mini: true,
                  elevation: 0,
                  backgroundColor: HomeColors.surfaceElevated,
                  shape: CircleBorder(
                    side: BorderSide(color: borderColor),
                  ),
                  onPressed: () async {
                    await _getCurrentLocation();
                    _fetchAvailableVehicles();
                  },
                  child: Icon(
                    Icons.my_location,
                    color: _isLoadingLocation
                        ? colorScheme.onSurfaceVariant
                        : _taxiGold,
                  ),
                ),
              ),
              // Bottom Sheet Modal
              DraggableScrollableSheet(
                initialChildSize: sheetInitial,
                minChildSize: 0.28,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  if (hasActiveRide) {
                    return _buildActiveRideSheet(context, scrollController);
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: HomeColors.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppColors.radiusXL),
                        topRight: Radius.circular(AppColors.radiusXL),
                      ),
                      border: Border(
                        top: BorderSide(color: borderColor),
                        left: BorderSide(color: borderColor),
                        right: BorderSide(color: borderColor),
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _taxiGold,
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
                    if (!hasActiveRide &&
                        _destinationPosition != null &&
                        (_routeDistanceKm != null || _isLoadingRoute))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(Icons.straighten,
                                size: 18, color: _taxiGold),
                            const SizedBox(width: 8),
                            if (_isLoadingRoute)
                              const _TaxiInlineShimmer(width: 72, height: 14)
                            else if (_routeDistanceKm != null)
                              Text(
                                l10n.taxiDistanceKm(
                                  _routeDistanceKm!.toStringAsFixed(2),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _taxiGold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (!hasActiveRide &&
                        _destinationPosition != null &&
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
                                color: HomeColors.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                border: Border.all(color: borderColor),
                              ),
                              child: TextField(
                                controller: _destinationController,
                                style: TextStyle(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: l10n.whereTo,
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: _taxiGold,
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
                                horizontal: AppColors.spaceMD,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: HomeColors.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: _taxiGold,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _timeChoice == _TaxiTimeChoice.now
                                        ? l10n.taxiTimeNow
                                        : l10n.taxiScheduleForLater,
                                    style: const TextStyle(
                                      color: _taxiGold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: _taxiGold,
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
                            borderColor: borderColor,
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
          );
        },
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
      return _TaxiMapShimmer();
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

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _toG(_currentPosition),
        zoom: 13.0,
      ),
      markers: _buildTaxiMarkers(hasActiveRide, activePickup, activeDropoff),
      polylines: _buildTaxiPolylines(hasActiveRide, activePickup, activeDropoff),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: gmaps.MapType.normal,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onTap: hasActiveRide ? null : _handleMapTap,
    );
  }
}

class _SuggestedLocationItem extends StatelessWidget {
  final String title;
  final String address;
  final Color borderColor;
  final VoidCallback onTap;

  const _SuggestedLocationItem({
    required this.title,
    required this.address,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppColors.spaceSM),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          child: Container(
            padding: const EdgeInsets.all(AppColors.spaceMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _taxiGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppColors.radiusMD),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: _taxiGold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppColors.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaxiInlineShimmer extends StatelessWidget {
  final double width;
  final double height;

  const _TaxiInlineShimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _TaxiMapShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(color: baseColor),
    );
  }
}

