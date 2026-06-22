import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/features/sos/presentation/widgets/sos_trigger_button.dart';

class DriverOnTheWayScreen extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupAddress;
  final String destinationAddress;
  final String tripType;
  final int price;
  final String paymentMethod;
  final int? rideId;

  const DriverOnTheWayScreen({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.tripType,
    required this.price,
    required this.paymentMethod,
    this.rideId,
  });

  @override
  State<DriverOnTheWayScreen> createState() => _DriverOnTheWayScreenState();
}

class _DriverOnTheWayScreenState extends State<DriverOnTheWayScreen> {
  gmaps.GoogleMapController? _mapController;
  LatLng? _driverPosition;
  List<LatLng>? _routePolylinePoints;
  double? _routeDistanceKm;
  bool _isLoadingRoute = true;
  bool? _hasGoogleMapsApiKey;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _loadMapsAvailability();

    // Calculate driver position (somewhere along the route)
    _driverPosition = LatLng(
      widget.pickupLocation.latitude +
          (widget.destinationLocation.latitude -
                  widget.pickupLocation.latitude) *
              0.3,
      widget.pickupLocation.longitude +
          (widget.destinationLocation.longitude -
                  widget.pickupLocation.longitude) *
              0.3,
    );
    _fetchRouteDirections();
  }

  Future<void> _loadMapsAvailability() async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (!mounted) return;
    setState(() {
      _hasGoogleMapsApiKey = key.trim().isNotEmpty;
    });
  }

  Future<void> _fetchRouteDirections() async {
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    const bottomSheetInitialFraction = 0.45;
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
          if (widget.rideId != null)
            Positioned(
              top: 40,
              right: 16,
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
                child: SosTriggerButton(
                  compact: true,
                  orderId: widget.rideId,
                ),
              ),
            ),
          // Bottom Sheet Modal
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.8,
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
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            const Text(
                              'Driver is on the way',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Driver Information
                            Row(
                              children: [
                                // Profile Picture
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Driver Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Driver',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Ann Wanjiru',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Contact Buttons
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryColor.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.message,
                                      color: AppColors.primaryColor,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement messaging
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryColor.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.phone,
                                      color: AppColors.primaryColor,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement calling
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Pickup and Drop-off
                            _LocationRow(
                              icon: Icons.location_on,
                              iconColor: Colors.green,
                              label: 'Pickup location',
                              address: widget.pickupAddress,
                              isFirst: true,
                            ),
                            // Dotted line
                            Padding(
                              padding: const EdgeInsets.only(left: 30),
                              child: Container(
                                height: 20,
                                child: CustomPaint(
                                  painter: _DottedLinePainter(),
                                  size: const Size(2, 20),
                                ),
                              ),
                            ),
                            _LocationRow(
                              icon: Icons.location_on,
                              iconColor: Colors.red,
                              label: 'Drop off',
                              address: widget.destinationAddress,
                              isFirst: false,
                            ),
                            if (_routeDistanceKm != null || _isLoadingRoute) ...[
                              const SizedBox(height: 16),
                              Row(
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
                            ],
                            const SizedBox(height: 24),
                            // Payment Information
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payment',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Card : ........ 7846',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'ETB ${widget.price}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
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
            gmaps.BitmapDescriptor.hueGreen,
          ),
        ),
        if (_driverPosition != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('driver'),
            position: _toG(_driverPosition!),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueYellow,
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

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;
  final bool isFirst;

  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isFirst ? iconColor.withOpacity(0.1) : Colors.transparent,
            shape: isFirst ? BoxShape.circle : BoxShape.rectangle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: isFirst ? 20 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 0.0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

