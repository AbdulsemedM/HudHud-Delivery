import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/features/taxi/data/ride_data_provider.dart';
import 'package:hudhud_delivery/features/guest/utils/guest_sign_in_prompt.dart';
import 'finding_driver_screen.dart';

class TripSelectionScreen extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupAddress;
  final String destinationAddress;
  final double? initialRouteDistanceKm;
  final List<LatLng>? initialRoutePolylinePoints;

  const TripSelectionScreen({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
    this.initialRouteDistanceKm,
    this.initialRoutePolylinePoints,
  });

  @override
  State<TripSelectionScreen> createState() => _TripSelectionScreenState();
}

class _TripSelectionScreenState extends State<TripSelectionScreen> {
  gmaps.GoogleMapController? _mapController;
  String? _selectedTrip;
  String _paymentMethod = 'wallet';
  bool _isLoadingEstimates = true;
  bool _isRequestingRide = false;
  String? _estimateError;
  final RideDataProvider _rideDataProvider = RideDataProvider();
  List<LatLng>? _routePolylinePoints;
  double? _routeDistanceKm;
  bool _isLoadingRoute = false;
  bool? _hasGoogleMapsApiKey;

  late List<TripOption> _tripOptions;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _loadMapsAvailability();
    _selectedTrip = 'go';
    _tripOptions = _getFallbackOptions();
    if (widget.initialRoutePolylinePoints != null && widget.initialRouteDistanceKm != null) {
      _routePolylinePoints = widget.initialRoutePolylinePoints;
      _routeDistanceKm = widget.initialRouteDistanceKm;
    } else {
      _fetchRouteDirections();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEstimates();
    });
  }

  Future<void> _loadMapsAvailability() async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (!mounted) return;
    setState(() {
      _hasGoogleMapsApiKey = key.trim().isNotEmpty;
    });
  }

  Future<void> _fetchRouteDirections() async {
    setState(() => _isLoadingRoute = true);
    final result = await GoogleDirectionsService.getDirections(
      originLat: widget.pickupLocation.latitude,
      originLng: widget.pickupLocation.longitude,
      destLat: widget.destinationLocation.latitude,
      destLng: widget.destinationLocation.longitude,
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

  void _fitBounds() {
    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(
        widget.pickupLocation.latitude < widget.destinationLocation.latitude
            ? widget.pickupLocation.latitude
            : widget.destinationLocation.latitude,
        widget.pickupLocation.longitude < widget.destinationLocation.longitude
            ? widget.pickupLocation.longitude
            : widget.destinationLocation.longitude,
      ),
      northeast: gmaps.LatLng(
        widget.pickupLocation.latitude > widget.destinationLocation.latitude
            ? widget.pickupLocation.latitude
            : widget.destinationLocation.latitude,
        widget.pickupLocation.longitude > widget.destinationLocation.longitude
            ? widget.pickupLocation.longitude
            : widget.destinationLocation.longitude,
      ),
    );
    _mapController?.moveCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  /// Maps trip option id to API vehicle_type and ride_type
  ({String vehicleType, String rideType}) _getApiParams(String tripId) {
    switch (tripId) {
      case 'go':
        return (vehicleType: 'car', rideType: 'standard');
      case 'tuk':
        return (vehicleType: 'auto', rideType: 'standard');
      case 'premier':
        return (vehicleType: 'car', rideType: 'premium');
      default:
        return (vehicleType: 'car', rideType: 'standard');
    }
  }

  Future<void> _fetchEstimates() async {
    if (!await requireSignInForBackend(context)) {
      if (mounted) {
        setState(() {
          _isLoadingEstimates = false;
          _tripOptions = _getFallbackOptions();
        });
      }
      return;
    }
    setState(() {
      _isLoadingEstimates = true;
      _estimateError = null;
    });

    final tripConfigs = [
      ('go', 'Hudhud Go', 'assets/images/car.png', true, false),
      ('tuk', 'Hudhud Tuk', 'assets/images/tuk.png', false, true),
      ('premier', 'HudHud Premier', 'assets/images/car.png', false, false),
    ];

    final options = <TripOption>[];
    for (final (id, name, imagePath, hasFasterBadge, isDiscount) in tripConfigs) {
      var params = _getApiParams(id);
      var result = await _rideDataProvider.getRideEstimate(
        pickupLatitude: widget.pickupLocation.latitude,
        pickupLongitude: widget.pickupLocation.longitude,
        dropoffLatitude: widget.destinationLocation.latitude,
        dropoffLongitude: widget.destinationLocation.longitude,
        vehicleType: params.vehicleType,
        rideType: params.rideType,
        passengerCount: 1,
      );
      if (result['data'] == null && params.vehicleType == 'auto') {
        params = (vehicleType: 'car', rideType: 'standard');
        result = await _rideDataProvider.getRideEstimate(
          pickupLatitude: widget.pickupLocation.latitude,
          pickupLongitude: widget.pickupLocation.longitude,
          dropoffLatitude: widget.destinationLocation.latitude,
          dropoffLongitude: widget.destinationLocation.longitude,
          vehicleType: params.vehicleType,
          rideType: params.rideType,
          passengerCount: 1,
        );
      }

      if (mounted && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final fare = (data['estimated_fare'] as num?)?.toDouble() ?? 0;
        final duration = (data['estimated_duration'] as int?) ?? 0;
        final eta = DateTime.now().add(Duration(minutes: duration));
        final dist = (data['estimated_distance'] as num?)?.toDouble();
        options.add(TripOption(
          id: id,
          name: name,
          price: fare.round(),
          originalPrice: isDiscount ? (fare * 1.1).round() : null,
          estimatedTime: '$duration min',
          estimatedArrival: '${eta.hour > 12 ? eta.hour - 12 : eta.hour}:${eta.minute.toString().padLeft(2, '0')}${eta.hour >= 12 ? 'pm' : 'am'}',
          vehicleImagePath: imagePath,
          hasFasterBadge: hasFasterBadge,
          isDiscount: isDiscount,
          estimatedDistance: dist,
          estimatedDuration: duration,
          vehicleType: params.vehicleType,
          rideType: params.rideType,
        ));
      } else {
        options.add(TripOption(
          id: id,
          name: name,
          price: 0,
          originalPrice: isDiscount ? 0 : null,
          estimatedTime: '--',
          estimatedArrival: '--',
          vehicleImagePath: imagePath,
          hasFasterBadge: hasFasterBadge,
          isDiscount: isDiscount,
          estimatedDistance: null,
          estimatedDuration: null,
          vehicleType: params.vehicleType,
          rideType: params.rideType,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _tripOptions = options.isEmpty ? _getFallbackOptions() : options;
        _isLoadingEstimates = false;
        if (options.every((o) => o.price == 0)) {
          _estimateError = 'Could not fetch estimates. Using default prices.';
        }
      });
    }
  }

  List<TripOption> _getFallbackOptions() {
    return [
      TripOption(
        id: 'go',
        name: 'Hudhud Go',
        price: 550,
        estimatedTime: '4 min away',
        estimatedArrival: '8:46pm',
        vehicleImagePath: 'assets/images/car.png',
        hasFasterBadge: true,
        vehicleType: 'car',
        rideType: 'standard',
      ),
      TripOption(
        id: 'tuk',
        name: 'Hudhud Tuk',
        price: 170,
        originalPrice: 188,
        estimatedTime: '4 min away',
        estimatedArrival: '8:46pm',
        vehicleImagePath: 'assets/images/tuk.png',
        isDiscount: true,
        vehicleType: 'car',
        rideType: 'standard',
      ),
      TripOption(
        id: 'premier',
        name: 'HudHud Premier',
        price: 223,
        estimatedTime: '5 min away',
        estimatedArrival: '8:46pm',
        vehicleImagePath: 'assets/images/car.png',
        vehicleType: 'car',
        rideType: 'premium',
      ),
    ];
  }

  Future<void> _onSelectTrip(TripOption selectedOption) async {
    if (_isRequestingRide) return;
    if (!await requireSignInForBackend(context)) return;

    setState(() => _isRequestingRide = true);

    final result = await _rideDataProvider.requestRide(
      pickupLocation: widget.pickupAddress,
      pickupLatitude: widget.pickupLocation.latitude,
      pickupLongitude: widget.pickupLocation.longitude,
      dropoffLocation: widget.destinationAddress,
      dropoffLatitude: widget.destinationLocation.latitude,
      dropoffLongitude: widget.destinationLocation.longitude,
      vehicleType: selectedOption.vehicleType,
      rideType: selectedOption.rideType,
      passengerCount: 1,
      estimatedDistance: selectedOption.estimatedDistance ?? 0,
      estimatedDuration: selectedOption.estimatedDuration ?? 0,
      estimatedFare: selectedOption.price.toDouble(),
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;

    setState(() => _isRequestingRide = false);

    if (result['statusCode'] != null && result['statusCode'] >= 200 && result['statusCode']! < 300) {
      final data = result['data'] as Map<String, dynamic>?;
      final ride = data?['ride'] as Map<String, dynamic>?;
      final rideId = ride?['id'] as int?;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindingDriverScreen(
            pickupLocation: widget.pickupLocation,
            destinationLocation: widget.destinationLocation,
            pickupAddress: widget.pickupAddress,
            destinationAddress: widget.destinationAddress,
            tripType: selectedOption.name,
            price: selectedOption.price,
            paymentMethod: _paymentMethod,
            rideId: rideId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['errorMessage'] ?? 'Failed to request ride'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = _tripOptions.firstWhere((opt) => opt.id == _selectedTrip);
    
    final screenHeight = MediaQuery.of(context).size.height;
    const bottomSheetInitialFraction = 0.5;
    final mapBottom = screenHeight * bottomSheetInitialFraction;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: mapBottom,
            child: _buildMapOrFallback(),
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
          // Bottom Sheet Modal
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
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
                    const SizedBox(height: 16),
                    // Distance in KM
                    if (_routeDistanceKm != null || _isLoadingRoute)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.straighten,
                                size: 18, color: AppColors.primaryColor),
                            const SizedBox(width: 8),
                            if (_isLoadingRoute)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_routeDistanceKm != null)
                              Text(
                                '${_routeDistanceKm!.toStringAsFixed(2)} KM',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (_routeDistanceKm != null || _isLoadingRoute)
                      const SizedBox(height: 12),
                    // Hint when road route failed (straight line = Directions API not enabled)
                    if (!_isLoadingRoute && _routePolylinePoints == null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Road route unavailable. Enable "Directions API" in Google Cloud Console for your API key (see MAPS_SETUP.md).',
                                style: TextStyle(fontSize: 11, color: Colors.orange[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Text(
                      'Choose a trip',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (_estimateError != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _estimateError!,
                          style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: _isLoadingEstimates
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _tripOptions.length,
                        itemBuilder: (context, index) {
                          final option = _tripOptions[index];
                          final isSelected = _selectedTrip == option.id;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TripOptionCard(
                              option: option,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedTrip = option.id;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Payment method selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text('Payment: ', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                          ...['wallet', 'card', 'cash'].map((method) {
                            final isSelected = _paymentMethod == method;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(method.toUpperCase()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) setState(() => _paymentMethod = method);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Select Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isRequestingRide
                              ? null
                              : () => _onSelectTrip(selectedOption),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Select ${selectedOption.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapOrFallback() {
    if (_hasGoogleMapsApiKey == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasGoogleMapsApiKey == false) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Google Maps is not configured on iOS. Add GOOGLE_MAPS_API_KEY and restart the app.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _toG(widget.pickupLocation),
        zoom: 13.0,
      ),
      markers: {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: _toG(widget.pickupLocation),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
        ),
        gmaps.Marker(
          markerId: const gmaps.MarkerId('destination'),
          position: _toG(widget.destinationLocation),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
        ),
      },
      polylines: {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          points: _routePolylinePoints != null && _routePolylinePoints!.length >= 2
              ? _routePolylinePoints!.map(_toG).toList()
              : [
                  _toG(widget.pickupLocation),
                  _toG(widget.destinationLocation),
                ],
          color: AppColors.primaryColor,
          width: 3,
        ),
      },
      myLocationEnabled: true,
      mapType: gmaps.MapType.normal,
      onMapCreated: (controller) {
        _mapController = controller;
        _fitBounds();
      },
    );
  }
}

class TripOption {
  final String id;
  final String name;
  final int price;
  final int? originalPrice;
  final String estimatedTime;
  final String estimatedArrival;
  final String vehicleImagePath;
  final bool hasFasterBadge;
  final bool isDiscount;
  final double? estimatedDistance;
  final int? estimatedDuration;
  final String vehicleType;
  final String rideType;

  TripOption({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.estimatedTime,
    required this.estimatedArrival,
    required this.vehicleImagePath,
    this.hasFasterBadge = false,
    this.isDiscount = false,
    this.estimatedDistance,
    this.estimatedDuration,
    this.vehicleType = 'car',
    this.rideType = 'standard',
  });
}

class _TripOptionCard extends StatelessWidget {
  final TripOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _TripOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Vehicle Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: option.id == 'tuk' 
                    ? Colors.yellow[50] 
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  option.vehicleImagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if image fails to load
                    return Icon(
                      option.id == 'tuk' ? Icons.moped : Icons.directions_car,
                      size: 50,
                      color: option.id == 'tuk' 
                          ? Colors.yellow[700] 
                          : Colors.grey[800],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Trip Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primaryColor
                                : const Color(0xFF2C3E50),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (option.hasFasterBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 12,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Faster',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${option.estimatedArrival} • ${option.estimatedTime}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (option.isDiscount && option.originalPrice != null) ...[
                  Text(
                    'ETB ${option.originalPrice}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ETB ${option.price}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ] else
                  Text(
                    'ETB ${option.price}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primaryColor
                          : const Color(0xFF2C3E50),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

