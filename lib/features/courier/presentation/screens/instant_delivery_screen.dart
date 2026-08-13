import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/app/services/geocoding_service.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import '../../../home/presentation/screen/location_search_screen.dart';
import 'package_details_screen.dart';

class InstantDeliveryScreen extends StatefulWidget {
  const InstantDeliveryScreen({super.key});

  @override
  State<InstantDeliveryScreen> createState() => _InstantDeliveryScreenState();
}

class _InstantDeliveryScreenState extends State<InstantDeliveryScreen> {
  gmaps.GoogleMapController? _mapController;
  String _pickupLocation = '';
  String _deliveryLocation = '';
  bool _pickupResolveFailed = false;
  String _selectedVehicle = 'motorcycle'; // motorcycle, car, van
  /// Default map center (Addis Ababa) — same as taxi / location flows until GPS resolves.
  LatLng _currentPosition = const LatLng(9.0222, 38.7468);
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
            _pickupResolveFailed = false;
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
            _pickupResolveFailed = true;
            _pickupLocation = '';
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pickupResolveFailed = true;
          _pickupLocation = '';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _selectPickupLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CourierTheme.wrap(
          context,
          child: LocationSearchScreen(
            currentLocation: _pickupLocation,
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      final address = result['address'] as String?;
      final coordinates = result['coordinates'] as LatLng?;

      if (address != null && coordinates != null) {
        setState(() {
          _pickupLocation = address;
          _pickupResolveFailed = false;
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
        builder: (context) => CourierTheme.wrap(
          context,
          child: LocationSearchScreen(
            currentLocation: _pickupLocation,
          ),
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

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final topPad = MediaQuery.paddingOf(context).top;
          const initialSheetSize = 0.5;

          return Scaffold(
            backgroundColor: HomeColors.background,
            body: Stack(
              children: [
                Positioned.fill(
                  child: _buildMapOrFallback(context),
                ),
                // Back button
                Positioned(
                  top: topPad + 8,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: HomeColors.surfaceElevated,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: HomeColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                // Recenter on current GPS — matches taxi / delivery map UX
                Positioned(
                  top: topPad + 8,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'instant_delivery_my_location',
                    mini: true,
                    backgroundColor: HomeColors.surfaceElevated,
                    onPressed: () async {
                      await _getCurrentLocation();
                      if (_pickupPosition != null && mounted) {
                        _mapController?.moveCamera(
                          gmaps.CameraUpdate.newLatLngZoom(
                            _toG(_pickupPosition!),
                            15,
                          ),
                        );
                      }
                    },
                    child: Icon(
                      Icons.my_location,
                      color: _isLoadingLocation
                          ? HomeColors.textMuted
                          : HomeColors.violet,
                    ),
                  ),
                ),
                // Bottom Sheet Modal
                DraggableScrollableSheet(
                  initialChildSize: initialSheetSize,
                  minChildSize: 0.3,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: HomeColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppColors.radiusLG),
                          topRight: Radius.circular(AppColors.radiusLG),
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
                              color: HomeColors.border,
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
                                  Text(
                                    l10n.courierInstantTitle,
                                    style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: HomeColors.textPrimary,
                                        ) ??
                                        const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: HomeColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Pickup Location (user can select)
                                  _LocationField(
                                    label: l10n.pickupLocationLabel,
                                    value: _isLoadingLocation
                                        ? l10n.locationGetting
                                        : (_pickupResolveFailed
                                            ? l10n.locationUnable
                                            : (_pickupLocation.isEmpty
                                                ? l10n.tapToSelectPickup
                                                : _pickupLocation)),
                                    icon: Icons.location_on,
                                    iconColor: colorScheme.error,
                                    isReadOnly: false,
                                    onTap: _selectPickupLocation,
                                  ),
                                  const SizedBox(height: 16),
                                  // Delivery Location (user can select)
                                  _LocationField(
                                    label: l10n.deliveryLocationLabel,
                                    value: _deliveryLocation.isEmpty
                                        ? l10n.tapToSelectDelivery
                                        : _deliveryLocation,
                                    icon: Icons.location_on,
                                    iconColor: HomeColors.violet,
                                    isReadOnly: false,
                                    onTap: _selectDeliveryLocation,
                                  ),
                                  const SizedBox(height: 24),
                                  // Vehicle Type
                                  Text(
                                    l10n.vehicleType,
                                    style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: HomeColors.textPrimary,
                                        ) ??
                                        const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: HomeColors.textPrimary,
                                        ),
                                  ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _VehicleTypeOption(
                                    icon: Icons.two_wheeler,
                                    label: l10n.vehicleMotorcycle,
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
                                    label: l10n.vehicleCar,
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
                                    label: l10n.vehicleVan,
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
                                      SnackBar(
                                        content: Text(
                                            l10n.selectPickupAndDelivery),
                                        backgroundColor:
                                            colorScheme.error,
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
                                        isInstantDelivery: true,
                                        scheduledPickup: null,
                                        scheduledDelivery: null,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HomeColors.violet,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppColors.radiusLG),
                                  ),
                                ),
                                child: Text(
                                  l10n.actionContinue,
                                  style: const TextStyle(
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
        },
      ),
    );
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
            content: Text(context.l10n.errorGettingAddress(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showLocationSelectionDialog(LatLng point) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          title: Text(
            l10n.selectLocationTitle,
            style: TextStyle(color: cs.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.location_on, color: cs.error),
                title: Text(
                  l10n.pickupLocationLabel,
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _handleMapTap(point, true);
                },
              ),
              ListTile(
                leading: Icon(Icons.location_on, color: cs.primary),
                title: Text(
                  l10n.deliveryLocationLabel,
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _handleMapTap(point, false);
                },
              ),
            ],
          ),
        );
      },
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

  Widget _buildMapOrFallback(BuildContext context) {
    final theme = Theme.of(context);
    if (_hasGoogleMapsApiKey == null) {
      return const ColoredBox(
        color: HomeColors.background,
        child: Center(
          child: CircularProgressIndicator(color: HomeColors.violet),
        ),
      );
    }
    if (_hasGoogleMapsApiKey == false) {
      return ColoredBox(
        color: HomeColors.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.taxiGoogleMapsNotConfigured,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: HomeColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _toG(_currentPosition),
        zoom: 15.0,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: gmaps.MapType.normal,
      markers: {
        if (_pickupPosition != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('pickup'),
            position: _toG(_pickupPosition!),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueAzure,
            ),
          ),
        if (_deliveryPosition != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('delivery'),
            position: _toG(_deliveryPosition!),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueRed,
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
                color: HomeColors.violet,
                width: 3,
              ),
            }
          : {},
      onMapCreated: (controller) {
        _mapController = controller;
        if (!_isLoadingLocation) {
          controller.moveCamera(
            gmaps.CameraUpdate.newLatLngZoom(_toG(_currentPosition), 15),
          );
        }
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
          color: HomeColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          border: Border.all(color: HomeColors.border),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: HomeColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: HomeColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isReadOnly)
              const Icon(Icons.chevron_right, color: HomeColors.textMuted),
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
              ? HomeColors.violet.withValues(alpha: 0.12)
              : HomeColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          border: Border.all(
            color: isSelected ? HomeColors.violet : HomeColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? HomeColors.violet
                  : HomeColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? HomeColors.violet
                    : HomeColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
