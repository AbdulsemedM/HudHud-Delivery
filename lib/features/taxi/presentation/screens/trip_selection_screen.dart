import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'finding_driver_screen.dart';

class TripSelectionScreen extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupAddress;
  final String destinationAddress;

  const TripSelectionScreen({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
  });

  @override
  State<TripSelectionScreen> createState() => _TripSelectionScreenState();
}

class _TripSelectionScreenState extends State<TripSelectionScreen> {
  late MapController _mapController;
  String? _selectedTrip;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedTrip = 'go'; // Default selection
    
    // Fit map to show both locations
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

  final List<TripOption> _tripOptions = [
    TripOption(
      id: 'go',
      name: 'Hudhud Go',
      price: 550,
      estimatedTime: '4 min away',
      estimatedArrival: '8:46pm',
      vehicleImagePath: 'assets/images/car.png',
      hasFasterBadge: true,
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
    ),
    TripOption(
      id: 'premier',
      name: 'HudHud Premier',
      price: 223,
      estimatedTime: '5 min away',
      estimatedArrival: '8:46pm',
      vehicleImagePath: 'assets/images/car.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedOption = _tripOptions.firstWhere((opt) => opt.id == _selectedTrip);
    
    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
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
                  Marker(
                    point: widget.pickupLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
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
                    const Text(
                      'Choose a trip',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Trip Options
                    Expanded(
                      child: ListView.builder(
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
                    // Select Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
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
                                  paymentMethod: 'Card',
                                ),
                              ),
                            );
                          },
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

