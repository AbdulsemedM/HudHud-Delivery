import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/core/widgets/location_search_field.dart';
import 'package:hudhud_delivery/app/services/nominatim_service.dart';
import 'package:hudhud_delivery/features/taxi/data/ride_data_provider.dart';
import 'finding_driver_screen.dart';
import 'driver_on_the_way_screen.dart';
import 'trip_selection_screen.dart';

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
  LatLng _currentPosition = const LatLng(37.7749, -122.4194); // Default to San Francisco
  LatLng? _destinationPosition;
  bool _isLoadingLocation = true;
  List<PlaceResult> _suggestedLocations = [];
  String? _selectedTime = 'Now';
  List<_AvailableDriver> _availableDrivers = [];
  int? _totalAvailable;
  int? _estimatedWaitTime;
  Map<String, dynamic>? _activeRide;
  bool _isCheckingActiveRide = true;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadSuggestedLocations();
    _checkActiveRide();
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
      }
    });

    if (_activeRide != null) {
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
      _mapController?.moveCamera(
        gmaps.CameraUpdate.newLatLngBounds(bounds, 80),
      );
    }
  }

  void _onTrackActiveRide() {
    if (_activeRide == null) return;

    final pickupLat = double.tryParse(_activeRide!['pickup_latitude']?.toString() ?? '');
    final pickupLng = double.tryParse(_activeRide!['pickup_longitude']?.toString() ?? '');
    final dropoffLat = double.tryParse(_activeRide!['dropoff_latitude']?.toString() ?? '');
    final dropoffLng = double.tryParse(_activeRide!['dropoff_longitude']?.toString() ?? '');
    final pickupLocation = _activeRide!['pickup_location'] as String? ?? 'Pickup';
    final dropoffLocation = _activeRide!['dropoff_location'] as String? ?? 'Destination';
    final status = _activeRide!['status'] as String? ?? 'searching';
    final vehicleType = _activeRide!['vehicle_type'] as String? ?? 'car';
    final rideType = _activeRide!['ride_type'] as String? ?? 'standard';
    final estimatedFare = (double.tryParse(_activeRide!['estimated_fare']?.toString() ?? '') ?? 0).round();
    final paymentMethod = _activeRide!['payment_method'] as String? ?? 'wallet';

    if (pickupLat == null || pickupLng == null || dropoffLat == null || dropoffLng == null) return;

    final pickup = LatLng(pickupLat, pickupLng);
    final dropoff = LatLng(dropoffLat, dropoffLng);
    final tripName = '${vehicleType[0].toUpperCase()}${vehicleType.substring(1)} (${rideType})';

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
      final results = await NominatimService.searchPlaces('Select Citywalk Mall');
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
    setState(() {
      _destinationPosition = place.coordinates;
      _destinationController.text = place.shortAddress;
    });

    // Navigate to trip selection screen
    if (_destinationPosition != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripSelectionScreen(
            pickupLocation: _currentPosition,
            destinationLocation: _destinationPosition!,
            pickupAddress: 'Current Location', // You can get this from geocoding
            destinationAddress: place.shortAddress,
          ),
        ),
      );
    }
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
      final places = await NominatimService.reverseGeocode(
        point.latitude,
        point.longitude,
      );

      if (mounted && places.isNotEmpty) {
        final place = places.first;
        setState(() {
          _destinationPosition = latLng;
          _destinationController.text = place.shortAddress;
          _isLoadingLocation = false;
        });

        // Move map to show the destination
        _mapController?.moveCamera(
          gmaps.CameraUpdate.newLatLngZoom(point, 15.0),
        );

        // Navigate to trip selection screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripSelectionScreen(
              pickupLocation: _currentPosition,
              destinationLocation: latLng,
              pickupAddress: 'Current Location',
              destinationAddress: place.shortAddress,
            ),
          ),
        );
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get location details'),
              backgroundColor: Colors.red,
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
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.primaryColor),
              title: const Text('Now'),
              onTap: () {
                setState(() {
                  _selectedTime = 'Now';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.primaryColor),
              title: const Text('Schedule for later'),
              onTap: () {
                // TODO: Implement time picker
                Navigator.pop(context);
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

  String get _activeRideStatusLabel {
    final status = _activeRide?['status'] as String? ?? '';
    switch (status) {
      case 'searching':
        return 'Finding a driver...';
      case 'accepted':
        return 'Driver on the way';
      case 'driver_arrived':
        return 'Driver has arrived';
      case 'started':
        return 'Trip in progress';
      default:
        return status.isNotEmpty ? status.replaceAll('_', ' ') : 'Active ride';
    }
  }

  Widget _buildActiveRideSheet() {
    final pickupLocation = _activeRide!['pickup_location'] as String? ?? 'Pickup';
    final dropoffLocation = _activeRide!['dropoff_location'] as String? ?? 'Destination';
    final estimatedFare = _activeRide!['estimated_fare']?.toString();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_taxi, color: AppColors.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Active Ride',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _activeRideStatusLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationRow(Icons.trip_origin, pickupLocation, Colors.blue),
                const SizedBox(height: 12),
                _buildLocationRow(Icons.location_on, dropoffLocation, Colors.red),
                if (estimatedFare != null && estimatedFare != 'null') ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Est. fare',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        '\$${double.tryParse(estimatedFare)?.toStringAsFixed(2) ?? estimatedFare}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _onTrackActiveRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Track Ride',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isCheckingActiveRide
                ? null
                : () {
                    setState(() => _isCheckingActiveRide = true);
                    _checkActiveRide();
                  },
            child: _isCheckingActiveRide
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Refresh status',
                    style: TextStyle(color: AppColors.primaryColor, fontSize: 14),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          points: [_toG(_currentPosition), _toG(_destinationPosition!)],
          color: AppColors.primaryColor,
          width: 3,
        ),
      );
    }
    if (hasActiveRide && activePickup != null && activeDropoff != null) {
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('active_route'),
          points: [_toG(activePickup), _toG(activeDropoff)],
          color: AppColors.primaryColor,
          width: 3,
        ),
      );
    }
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveRide = _activeRide != null;
    final activePickup = _activePickup;
    final activeDropoff = _activeDropoff;

    return Scaffold(
      body: Stack(
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(
              target: _toG(_currentPosition),
              zoom: 13.0,
            ),
            markers: _buildTaxiMarkers(hasActiveRide, activePickup, activeDropoff),
            polylines: _buildTaxiPolylines(hasActiveRide, activePickup, activeDropoff),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: hasActiveRide ? null : _handleMapTap,
          ),
          // Available cars info chip - hide when active ride
          if (!hasActiveRide && _totalAvailable != null && _totalAvailable! > 0)
            Positioned(
              top: 95,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_taxi, color: AppColors.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$_totalAvailable car${_totalAvailable! > 1 ? 's' : ''} nearby',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (_estimatedWaitTime != null && _estimatedWaitTime! > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '~$_estimatedWaitTime min',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
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
              backgroundColor: Colors.white,
              onPressed: () async {
                await _getCurrentLocation();
                _fetchAvailableVehicles();
              },
              child: Icon(
                Icons.my_location,
                color: _isLoadingLocation ? Colors.grey : Colors.blue,
              ),
            ),
          ),
          // Bottom Sheet Modal
          DraggableScrollableSheet(
            initialChildSize: hasActiveRide ? 0.45 : 0.35,
            minChildSize: 0.25,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              if (hasActiveRide) {
                return _buildActiveRideSheet();
              }
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
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
                        color: Colors.grey[300],
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
                            'HUDHUD',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          Text(
                            ' delivery',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search Bar and Now Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Search Bar
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _destinationController,
                                decoration: InputDecoration(
                                  hintText: 'Where to?',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppColors.primaryColor,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onTap: () {
                                  // Show location search
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Container(
                                      height: MediaQuery.of(context).size.height * 0.7,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: LocationSearchField(
                                              hintText: 'Where to?',
                                              onLocationSelected: (place) {
                                                _onLocationSelected(place);
                                                Navigator.pop(context);
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: AppColors.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedTime ?? 'Now',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppColors.primaryColor,
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.access_time,
              color: AppColors.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

