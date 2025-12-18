import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/core/widgets/location_search_field.dart';
import 'package:hudhud_delivery/app/services/nominatim_service.dart';
import 'trip_selection_screen.dart';

class TaxiScreen extends StatefulWidget {
  const TaxiScreen({super.key});

  @override
  State<TaxiScreen> createState() => _TaxiScreenState();
}

class _TaxiScreenState extends State<TaxiScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _destinationController = TextEditingController();
  LatLng _currentPosition = const LatLng(37.7749, -122.4194); // Default to San Francisco
  LatLng? _destinationPosition;
  bool _isLoadingLocation = true;
  List<PlaceResult> _suggestedLocations = [];
  String? _selectedTime = 'Now';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadSuggestedLocations();
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

          _mapController.move(_currentPosition, 13.0);
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

  Future<void> _handleMapTap(TapPosition tapPosition, LatLng point) async {
    // Don't set destination if user tapped on their current location
    final distance = _calculateDistance(_currentPosition, point);
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
          _destinationPosition = point;
          _destinationController.text = place.shortAddress;
          _isLoadingLocation = false;
        });

        // Move map to show the destination
        _mapController.move(point, 15.0);

        // Navigate to trip selection screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripSelectionScreen(
              pickupLocation: _currentPosition,
              destinationLocation: point,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: _handleMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hudhuddelivery.app',
                maxZoom: 18,
              ),
              MarkerLayer(
                markers: [
                  // Current location marker
                  Marker(
                    point: _currentPosition,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                  // Destination marker
                  if (_destinationPosition != null)
                    Marker(
                      point: _destinationPosition!,
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
              // Polyline if destination is selected
              if (_destinationPosition != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_currentPosition, _destinationPosition!],
                      strokeWidth: 3.0,
                      color: AppColors.primaryColor,
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
          // Current location button
          Positioned(
            right: 16,
            top: 100,
            child: FloatingActionButton(
              heroTag: 'current_location',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: Icon(
                Icons.my_location,
                color: _isLoadingLocation ? Colors.grey : Colors.blue,
              ),
            ),
          ),
          // Bottom Sheet Modal
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.25,
            maxChildSize: 0.75,
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

