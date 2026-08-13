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

class ScheduleDeliveryScreen extends StatefulWidget {
  const ScheduleDeliveryScreen({super.key});

  @override
  State<ScheduleDeliveryScreen> createState() => _ScheduleDeliveryScreenState();
}

class _ScheduleDeliveryScreenState extends State<ScheduleDeliveryScreen> {
  gmaps.GoogleMapController? _mapController;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _pickupLocation = '';
  String _deliveryLocation = '';
  bool _pickupResolveFailed = false;
  String _selectedVehicle = 'motorcycle'; // motorcycle, car, van
  String _timePeriod = 'pm'; // am or pm
  /// Default map center (Addis Ababa) — same as taxi / instant until GPS resolves.
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
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final latLng = LatLng(position.latitude, position.longitude);

        final address = await GeocodingService.getAddressFromLatLng(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() {
            _currentPosition = latLng;
            _pickupPosition = latLng;
            _pickupLocation = address;
            _pickupResolveFailed = false;
            _isLoadingLocation = false;
          });

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
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final topPad = MediaQuery.paddingOf(context).top;
          const initialSheetSize = 0.55;

          return Scaffold(
            backgroundColor: HomeColors.background,
            body: Stack(
              children: [
                Positioned.fill(
                  child: _buildMapOrFallback(context),
                ),
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
                Positioned(
                  top: topPad + 8,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'schedule_delivery_my_location',
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
                DraggableScrollableSheet(
                  initialChildSize: initialSheetSize,
                  minChildSize: 0.35,
                  maxChildSize: 0.9,
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
                                    l10n.courierScheduleTitle,
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
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.courierScheduleSubtitle,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: HomeColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
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
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.labelDate,
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                color: HomeColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: _selectDate,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: HomeColors
                                                      .surfaceElevated,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: HomeColors.border,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _dateController
                                                                .text.isEmpty
                                                            ? l10n
                                                                .hintDateFormat
                                                            : _dateController
                                                                .text,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: _dateController
                                                                  .text.isEmpty
                                                              ? HomeColors
                                                                  .textMuted
                                                              : HomeColors
                                                                  .textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    const Icon(
                                                      Icons.calendar_today,
                                                      size: 20,
                                                      color:
                                                          HomeColors.textMuted,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.labelTime,
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                color: HomeColors.textPrimary,
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
                                                          const EdgeInsets.all(
                                                              16),
                                                      decoration: BoxDecoration(
                                                        color: HomeColors
                                                            .surfaceElevated,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: HomeColors
                                                              .border,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        _timeController
                                                                .text.isEmpty
                                                            ? l10n
                                                                .hintTimeFormat
                                                            : _timeController
                                                                .text,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: _timeController
                                                                  .text.isEmpty
                                                              ? HomeColors
                                                                  .textMuted
                                                              : HomeColors
                                                                  .textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: HomeColors
                                                        .surfaceElevated,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: HomeColors.border,
                                                    ),
                                                  ),
                                                  child:
                                                      DropdownButtonHideUnderline(
                                                    child:
                                                        DropdownButton<String>(
                                                      value: _timePeriod,
                                                      dropdownColor: HomeColors
                                                          .surfaceElevated,
                                                      style: const TextStyle(
                                                        color: HomeColors
                                                            .textPrimary,
                                                        fontSize: 14,
                                                      ),
                                                      items: [
                                                        DropdownMenuItem(
                                                          value: 'am',
                                                          child: Text(
                                                              l10n.meridiemAm),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'pm',
                                                          child: Text(
                                                              l10n.meridiemPm),
                                                        ),
                                                      ],
                                                      onChanged: (value) {
                                                        if (value == null) {
                                                          return;
                                                        }
                                                        setState(() {
                                                          _timePeriod = value;
                                                        });
                                                      },
                                                    ),
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
                                          isSelected: _selectedVehicle ==
                                              'motorcycle',
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
                                          isSelected:
                                              _selectedVehicle == 'car',
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
                                          isSelected:
                                              _selectedVehicle == 'van',
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
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_pickupLocation.isEmpty ||
                                            _deliveryLocation.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(l10n
                                                  .selectPickupAndDelivery),
                                              backgroundColor:
                                                  colorScheme.error,
                                            ),
                                          );
                                          return;
                                        }
                                        if (_dateController.text.isEmpty ||
                                            _timeController.text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(l10n
                                                  .scheduleSelectDateTime),
                                              backgroundColor:
                                                  colorScheme.error,
                                            ),
                                          );
                                          return;
                                        }

                                        final scheduledDateTime =
                                            _parseScheduledDateTime();
                                        if (scheduledDateTime == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(l10n
                                                  .scheduleInvalidDateTime),
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
                                              deliveryLocation:
                                                  _deliveryLocation,
                                              pickupPosition: _pickupPosition,
                                              deliveryPosition:
                                                  _deliveryPosition,
                                              selectedVehicle:
                                                  _selectedVehicle,
                                              isInstantDelivery: false,
                                              scheduledPickup:
                                                  scheduledDateTime,
                                              scheduledDelivery:
                                                  scheduledDateTime,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: HomeColors.violet,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppColors.radiusLG),
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

  Widget _buildMapOrFallback(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
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
              l10n.taxiGoogleMapsNotConfigured,
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
                points: _routePolylinePoints != null &&
                        _routePolylinePoints!.length >= 2
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
              color: isSelected ? HomeColors.violet : HomeColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? HomeColors.violet : HomeColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
