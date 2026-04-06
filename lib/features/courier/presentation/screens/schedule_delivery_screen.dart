import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/app/services/geocoding_service.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import '../../../home/presentation/screen/location_search_screen.dart';
import 'package_details_screen.dart';

class ScheduleDeliveryScreen extends StatefulWidget {
  const ScheduleDeliveryScreen({super.key});

  @override
  State<ScheduleDeliveryScreen> createState() => _ScheduleDeliveryScreenState();
}

class _ScheduleDeliveryScreenState extends State<ScheduleDeliveryScreen> {
  gmaps.GoogleMapController? _mapController;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _pickupLocation = 'Getting location...';
  String _deliveryLocation = '';
  String _selectedVehicle = 'motorcycle'; // motorcycle, car, van
  String _timePeriod = 'pm'; // am or pm
  LatLng _currentPosition = const LatLng(37.7749, -122.4194); // Default
  LatLng? _pickupPosition;
  LatLng? _deliveryPosition;
  bool _isLoadingLocation = true;
  List<LatLng>? _routePolylinePoints;
  bool? _hasGoogleMapsApiKey;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  Future<void> _fetchRouteDirections() async {
    if (_pickupPosition == null || _deliveryPosition == null) return;
    final result = await GoogleDirectionsService.getDirections(
      originLat: _pickupPosition!.latitude,
      originLng: _pickupPosition!.longitude,
      destLat: _deliveryPosition!.latitude,
      destLng: _deliveryPosition!.longitude,
    );
    if (!mounted) return;
    setState(() {
      _routePolylinePoints = result?.polylinePoints;
    });
  }

  @override
  void initState() {
    super.initState();
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
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Get current position coordinates
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final latLng = LatLng(position.latitude, position.longitude);

        // Get address from coordinates
        final address = await GeocodingService.getAddressFromLatLng(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() {
            _currentPosition = latLng;
            _pickupPosition = latLng; // Set initial pickup position
            _pickupLocation = address;
            _isLoadingLocation = false;
          });

          // Move map to current location
          _mapController?.moveCamera(
            gmaps.CameraUpdate.newLatLngZoom(_toG(latLng), 15.0),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _pickupLocation = 'Unable to get location';
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pickupLocation = 'Unable to get location';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _selectPickupLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSearchScreen(
          currentLocation: _pickupLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      final address = result['address'] as String?;
      final coordinates = result['coordinates'] as LatLng?;

      if (address != null && coordinates != null) {
        setState(() {
          _pickupLocation = address;
          _pickupPosition = coordinates;
          _routePolylinePoints = null;
        });

        // Adjust map view to show both locations if both are set
        if (_pickupPosition != null && _deliveryPosition != null) {
          _fetchRouteDirections();
          _fitBounds();
        } else {
          _mapController?.moveCamera(
            gmaps.CameraUpdate.newLatLngZoom(_toG(coordinates), 15.0),
          );
        }
      }
    }
  }

  Future<void> _selectDeliveryLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSearchScreen(
          currentLocation: _pickupLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      final address = result['address'] as String?;
      final coordinates = result['coordinates'] as LatLng?;

      if (address != null && coordinates != null) {
        setState(() {
          _deliveryLocation = address;
          _deliveryPosition = coordinates;
          _routePolylinePoints = null;
        });

        // Adjust map view to show both locations if both are set
        if (_pickupPosition != null && _deliveryPosition != null) {
          _fetchRouteDirections();
          _fitBounds();
        } else {
          _mapController?.moveCamera(
            gmaps.CameraUpdate.newLatLngZoom(_toG(coordinates), 15.0),
          );
        }
      }
    }
  }

  Future<void> _handleMapTap(LatLng point, bool isPickup) async {
    try {
      // Get address from tapped location
      final address = await GeocodingService.getAddressFromLatLng(
        point.latitude,
        point.longitude,
      );

      if (mounted) {
        setState(() {
          if (isPickup) {
            _pickupLocation = address;
            _pickupPosition = point;
          } else {
            _deliveryLocation = address;
            _deliveryPosition = point;
          }
          _routePolylinePoints = null;
        });

        // Adjust map view to show both locations if both are set
        if (_pickupPosition != null && _deliveryPosition != null) {
          _fetchRouteDirections();
          _fitBounds();
        } else {
          _mapController?.moveCamera(
            gmaps.CameraUpdate.newLatLngZoom(_toG(point), 15.0),
          );
        }
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationSelectionDialog(LatLng point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('Pickup Location'),
              onTap: () {
                Navigator.pop(context);
                _handleMapTap(point, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: const Text('Delivery Location'),
              onTap: () {
                Navigator.pop(context);
                _handleMapTap(point, false);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _fitBounds() {
    if (_pickupPosition != null && _deliveryPosition != null) {
      final bounds = gmaps.LatLngBounds(
        southwest: gmaps.LatLng(
          _pickupPosition!.latitude < _deliveryPosition!.latitude
              ? _pickupPosition!.latitude
              : _deliveryPosition!.latitude,
          _pickupPosition!.longitude < _deliveryPosition!.longitude
              ? _pickupPosition!.longitude
              : _deliveryPosition!.longitude,
        ),
        northeast: gmaps.LatLng(
          _pickupPosition!.latitude > _deliveryPosition!.latitude
              ? _pickupPosition!.latitude
              : _deliveryPosition!.latitude,
          _pickupPosition!.longitude > _deliveryPosition!.longitude
              ? _pickupPosition!.longitude
              : _deliveryPosition!.longitude,
        ),
      );
      _mapController?.moveCamera(
        gmaps.CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  DateTime? _parseScheduledDateTime() {
    final dateStr = _dateController.text;
    final timeStr = _timeController.text;
    if (dateStr.isEmpty || timeStr.isEmpty) return null;

    final dateParts = dateStr.split('/');
    if (dateParts.length != 3) return null;
    final day = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final year = int.tryParse(dateParts[2]);
    if (day == null || month == null || year == null) return null;

    final timeParts = timeStr.split(':');
    if (timeParts.length != 2) return null;
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return null;

    try {
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _timePeriod = picked.period == DayPeriod.am ? 'am' : 'pm';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMapOrFallback(),
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
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // Bottom Sheet Modal
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.9,
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
                            const Text(
                              'Schedule Delivery',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Pickup Location (user can select)
                            _LocationField(
                              label: 'Pickup Location',
                              value: _isLoadingLocation
                                  ? 'Getting location...'
                                  : (_pickupLocation.isEmpty
                                      ? 'Tap to select pickup location'
                                      : _pickupLocation),
                              icon: Icons.location_on,
                              iconColor: Colors.red,
                              isReadOnly: false,
                              onTap: _selectPickupLocation,
                            ),
                            const SizedBox(height: 16),
                            // Delivery Location (user can select)
                            _LocationField(
                              label: 'Delivery Location',
                              value: _deliveryLocation.isEmpty
                                  ? 'Tap to select delivery location'
                                  : _deliveryLocation,
                              icon: Icons.location_on,
                              iconColor: Colors.green,
                              isReadOnly: false,
                              onTap: _selectDeliveryLocation,
                            ),
                            const SizedBox(height: 16),
                            // Date and Time Row
                            Row(
                              children: [
                                // Date Field
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Date',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: _selectDate,
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _dateController.text.isEmpty
                                                      ? 'DD/MM/YYYY'
                                                      : _dateController.text,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: _dateController
                                                            .text.isEmpty
                                                        ? Colors.grey[400]
                                                        : const Color(
                                                            0xFF2C3E50),
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.calendar_today,
                                                  size: 20,
                                                  color: Colors.grey[400]),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Time Field
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Time',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: _selectTime,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: Colors.grey[200]!),
                                                ),
                                                child: Text(
                                                  _timeController.text.isEmpty
                                                      ? 'HH:MM'
                                                      : _timeController.text,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: _timeController
                                                            .text.isEmpty
                                                        ? Colors.grey[400]
                                                        : const Color(
                                                            0xFF2C3E50),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey[200]!),
                                            ),
                                            child: DropdownButton<String>(
                                              value: _timePeriod,
                                              underline: const SizedBox(),
                                              items: ['am', 'pm']
                                                  .map((period) =>
                                                      DropdownMenuItem(
                                                        value: period,
                                                        child: Text(period),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _timePeriod = value!;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Vehicle Type
                            const Text(
                              'Vehicle Type',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _VehicleTypeOption(
                                    icon: Icons.two_wheeler,
                                    label: 'Motorcycle',
                                    isSelected:
                                        _selectedVehicle == 'motorcycle',
                                    onTap: () {
                                      setState(() {
                                        _selectedVehicle = 'motorcycle';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _VehicleTypeOption(
                                    icon: Icons.directions_car,
                                    label: 'Car',
                                    isSelected: _selectedVehicle == 'car',
                                    onTap: () {
                                      setState(() {
                                        _selectedVehicle = 'car';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _VehicleTypeOption(
                                    icon: Icons.airport_shuttle,
                                    label: 'Van',
                                    isSelected: _selectedVehicle == 'van',
                                    onTap: () {
                                      setState(() {
                                        _selectedVehicle = 'van';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Continue Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_pickupLocation.isEmpty ||
                                      _deliveryLocation.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please select both pickup and delivery locations'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  if (_dateController.text.isEmpty ||
                                      _timeController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please select date and time for delivery'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  final scheduledDateTime =
                                      _parseScheduledDateTime();
                                  if (scheduledDateTime == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Invalid date or time format'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PackageDetailsScreen(
                                        pickupLocation: _pickupLocation,
                                        deliveryLocation: _deliveryLocation,
                                        pickupPosition: _pickupPosition,
                                        deliveryPosition: _deliveryPosition,
                                        selectedVehicle: _selectedVehicle,
                                        isInstantDelivery: false,
                                        scheduledPickup: scheduledDateTime,
                                        scheduledDelivery: scheduledDateTime,
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
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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
        target: _toG(_currentPosition),
        zoom: 15.0,
      ),
      markers: {
        if (_pickupPosition != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('pickup'),
            position: _toG(_pickupPosition!),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueRed,
            ),
          ),
        if (_deliveryPosition != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('delivery'),
            position: _toG(_deliveryPosition!),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueGreen,
            ),
          ),
      },
      polylines: _pickupPosition != null && _deliveryPosition != null
          ? {
              gmaps.Polyline(
                polylineId: const gmaps.PolylineId('route'),
                points: _routePolylinePoints != null && _routePolylinePoints!.length >= 2
                    ? _routePolylinePoints!.map(_toG).toList()
                    : [_toG(_pickupPosition!), _toG(_deliveryPosition!)],
                color: AppColors.primaryColor,
                width: 3,
              ),
            }
          : {},
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onTap: (point) {
        _showLocationSelectionDialog(LatLng(point.latitude, point.longitude));
      },
    );
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isReadOnly;
  final VoidCallback onTap;

  const _LocationField({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.isReadOnly = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
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
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
            if (!isReadOnly) Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

}

class _VehicleTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleTypeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primaryColor : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primaryColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
