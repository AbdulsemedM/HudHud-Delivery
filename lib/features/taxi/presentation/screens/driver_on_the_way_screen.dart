import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class DriverOnTheWayScreen extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupAddress;
  final String destinationAddress;
  final String tripType;
  final int price;
  final String paymentMethod;

  const DriverOnTheWayScreen({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.tripType,
    required this.price,
    required this.paymentMethod,
  });

  @override
  State<DriverOnTheWayScreen> createState() => _DriverOnTheWayScreenState();
}

class _DriverOnTheWayScreenState extends State<DriverOnTheWayScreen> {
  late MapController _mapController;
  LatLng? _driverPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Calculate driver position (somewhere along the route)
    _driverPosition = LatLng(
      widget.pickupLocation.latitude + 
      (widget.destinationLocation.latitude - widget.pickupLocation.latitude) * 0.3,
      widget.pickupLocation.longitude + 
      (widget.destinationLocation.longitude - widget.pickupLocation.longitude) * 0.3,
    );
    
    // Fit map to show route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  void _fitBounds() {
    final bounds = LatLngBounds(widget.pickupLocation, widget.destinationLocation);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Map Section (Top Half)
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.pickupLocation,
                    initialZoom: 13.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hudhuddelivery.app',
                      maxZoom: 18,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [widget.pickupLocation, widget.destinationLocation],
                          strokeWidth: 3.0,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // Pickup marker (green circle)
                        Marker(
                          point: widget.pickupLocation,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                        // Driver position (yellow taxi icon)
                        if (_driverPosition != null)
                          Marker(
                            point: _driverPosition!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.yellow[600],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_taxi,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        // Destination marker (red pin)
                        Marker(
                          point: widget.destinationLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
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
              ],
            ),
          ),
          // Details Panel (Bottom Half)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Padding(
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
              ],
            ),
          ),
        ],
      ),
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

