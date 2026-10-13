import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/app/services/geocoding_service.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/delivery_estimate_banner.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/nearby_driver_markers.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/send_package_location_row.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_vehicle_display.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_estimate.dart';
import 'package:hudhud_delivery/features/courier/utils/nearby_drivers_poller.dart';
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
  late final CourierRepository _courierRepository;
  late final NearbyDriversPoller _nearbyPoller;
  Timer? _estimateDebounce;
  Timer? _serviceAreaDebounce;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _pickupLocation = '';
  String _deliveryLocation = '';
  bool _pickupResolveFailed = false;
  String? _selectedVehicle;
  String _timePeriod = 'pm'; // am or pm
  /// Default map center (Addis Ababa) — same as taxi / instant until GPS resolves.
  LatLng _currentPosition = const LatLng(9.0222, 38.7468);
  LatLng? _pickupPosition;
  LatLng? _deliveryPosition;
  bool _isLoadingLocation = true;
  List<LatLng>? _routePolylinePoints;
  bool? _hasGoogleMapsApiKey;
  bool _isLoadingEstimate = false;
  String? _estimateError;
  double? _estimatedCost;
  double? _estimatedDistance;
  int? _estimatedDuration;
  String _estimatedCurrency = 'ETB';
  String? _quotedScheduledPickup;
  bool _isLoadingServiceArea = false;
  List<String> _supportedVehicleTypes = const [];
  Map<String, gmaps.BitmapDescriptor> _nearbyIconsByAsset = {};

  bool get _canFetchEstimate =>
      _pickupPosition != null &&
      _deliveryPosition != null &&
      _supportedVehicleTypes.isNotEmpty &&
      _selectedVehicle != null &&
      _dateController.text.isNotEmpty &&
      _timeController.text.isNotEmpty &&
      _parseScheduledDateTime() != null;

  bool get _hasServerEstimate =>
      !_isLoadingEstimate &&
      _estimateError == null &&
      _estimatedCost != null &&
      _quotedScheduledPickup != null;

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
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _nearbyPoller = NearbyDriversPoller(
      repository: _courierRepository,
      onUpdate: () => unawaited(_onNearbyDriversUpdated()),
    );
    unawaited(preloadCommonCourierVehicleMapIcons());
    _loadMapsAvailability();
    _getCurrentLocation();
  }

  Future<void> _onNearbyDriversUpdated() async {
    await preloadCourierVehicleMapIcons(
      _nearbyPoller.result.drivers.map((d) => d.vehicleType),
    );
    if (mounted) {
      setState(() {
        _nearbyIconsByAsset = CourierVehicleMapIconCache.snapshot();
      });
    }
  }

  void _syncNearbyDrivers() {
    final pickup = _pickupPosition;
    final vehicle = _selectedVehicle;
    if (pickup == null || vehicle == null) return;
    _nearbyPoller.setTarget(
      latitude: pickup.latitude,
      longitude: pickup.longitude,
      vehicleType: mapCourierVehicleType(vehicle),
    );
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
    _estimateDebounce?.cancel();
    _serviceAreaDebounce?.cancel();
    _nearbyPoller.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _scheduleServiceAreaFetch() {
    _serviceAreaDebounce?.cancel();
    if (_pickupLocation.trim().isEmpty) {
      setState(() {
        _isLoadingServiceArea = false;
        _supportedVehicleTypes = const [];
        _selectedVehicle = null;
      });
      return;
    }
    _serviceAreaDebounce = Timer(
      const Duration(milliseconds: 300),
      _fetchServiceArea,
    );
  }

  Future<void> _fetchServiceArea({bool quoteAfter = true}) async {
    final pickup = _pickupLocation.trim();
    if (pickup.isEmpty) return;

    setState(() {
      _isLoadingServiceArea = true;
    });

    final result = await _courierRepository.getDeliveryServiceAreas(
      pickupLocation: pickup,
    );
    if (!mounted) return;

    final rawTypes = result['success'] == true
        ? List<String>.from(
            result['supportedVehicleTypes'] as List? ?? const [])
        : const <String>[];
    final applied = applyCourierSupportedVehicleTypes(
      supportedVehicleTypes: rawTypes,
      selectedVehicleType: _selectedVehicle,
    );
    setState(() {
      _isLoadingServiceArea = false;
      _supportedVehicleTypes = applied.types;
      _selectedVehicle = applied.selected;
    });
    _syncNearbyDrivers();
    if (quoteAfter) _scheduleEstimateFetch();
  }

  void _scheduleEstimateFetch() {
    _estimateDebounce?.cancel();
    if (!_canFetchEstimate) {
      setState(() {
        _isLoadingEstimate = false;
        _estimateError = null;
        _estimatedCost = null;
        _estimatedDistance = null;
        _estimatedDuration = null;
        _quotedScheduledPickup = null;
      });
      return;
    }
    _estimateDebounce = Timer(
      const Duration(milliseconds: 300),
      _fetchEstimate,
    );
  }

  Future<void> _fetchEstimate() async {
    if (_pickupPosition == null ||
        _deliveryPosition == null ||
        _selectedVehicle == null) {
      return;
    }

    final scheduled = _parseScheduledDateTime();
    if (scheduled == null) return;
    final scheduledPickup = formatDeliveryScheduledPickup(scheduled);

    setState(() {
      _isLoadingEstimate = true;
      _estimateError = null;
      _quotedScheduledPickup = null;
    });

    final result = await _courierRepository.estimateDelivery(
      packageType: kCourierEstimatePlaceholderPackageType,
      packageWeight: kCourierEstimatePlaceholderWeightKg,
      pickupLatitude: _pickupPosition!.latitude,
      pickupLongitude: _pickupPosition!.longitude,
      dropoffLatitude: _deliveryPosition!.latitude,
      dropoffLongitude: _deliveryPosition!.longitude,
      vehicleType: mapCourierVehicleType(_selectedVehicle!),
      serviceType: deliveryServiceType(isInstantDelivery: false),
      pickupLocation: _pickupLocation,
      scheduledPickup: scheduledPickup,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingEstimate = false;
      if (result['success'] == true) {
        _estimatedCost = result['estimatedCost'] as double?;
        _estimatedDistance = result['estimatedDistance'] as double?;
        _estimatedDuration = result['estimatedDuration'] as int?;
        _estimatedCurrency = result['currency'] as String? ?? 'ETB';
        _quotedScheduledPickup =
            result['scheduledPickup'] as String? ?? scheduledPickup;
        _estimateError =
            _estimatedCost == null ? 'Estimate did not include a cost' : null;
        if (_estimateError != null) {
          _quotedScheduledPickup = null;
        }
      } else {
        final error = result['error'] as ApiErrorResult?;
        if (error?.isPickupServiceAreaUnavailable == true) {
          _estimateError = context.l10n.pickupOutsideDeliveryServiceArea;
        } else if (error?.isCityVehicleNotSupported == true) {
          _estimateError = result['message'] as String?;
        } else if (error?.hasScheduledPickupValidation == true) {
          _estimateError = context.l10n.chooseValidFuturePickup;
        } else if (error?.isRouteDistanceError == true) {
          _estimateError = context.l10n.refreshQuoteRouteDistance;
        } else {
          _estimateError = result['message'] as String?;
        }
        _estimatedCost = null;
        _estimatedDistance = null;
        _estimatedDuration = null;
        _quotedScheduledPickup = null;
      }
    });
    if ((result['error'] as ApiErrorResult?)?.isPickupServiceAreaUnavailable ==
        true) {
      setState(() {
        _supportedVehicleTypes = const [];
        _selectedVehicle = null;
      });
    } else if ((result['error'] as ApiErrorResult?)
            ?.isCityVehicleNotSupported ==
        true) {
      await _fetchServiceArea(quoteAfter: false);
    }
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
          _syncNearbyDrivers();
          _scheduleServiceAreaFetch();
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
          _scheduleEstimateFetch();
        } else {
          _scheduleEstimateFetch();
          _mapController?.moveCamera(
            gmaps.CameraUpdate.newLatLngZoom(_toG(coordinates), 15.0),
          );
        }
        _syncNearbyDrivers();
        _scheduleServiceAreaFetch();
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
          _scheduleEstimateFetch();
        } else {
          _scheduleEstimateFetch();
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
          _scheduleEstimateFetch();
        } else {
          _scheduleEstimateFetch();
          _mapController?.moveCamera(
            gmaps.CameraUpdate.newLatLngZoom(_toG(point), 15.0),
          );
        }
        if (isPickup) {
          _syncNearbyDrivers();
          _scheduleServiceAreaFetch();
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
                leading: const Icon(Icons.my_location_rounded,
                    color: HomeColors.orange),
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
                leading: Icon(Icons.location_on_rounded,
                    color: HomeColors.violetOf(dialogContext)),
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

  /// Brand-styled date / time pickers: orange selection, indigo accents,
  /// token surfaces, rounded dialog.
  Widget _pickerThemeBuilder(BuildContext context, Widget? child) {
    final base = Theme.of(context);
    final surface = HomeColors.surfaceOf(context);
    final textPrimary = HomeColors.textPrimaryOf(context);
    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: HomeColors.orange,
          onPrimary: Colors.white,
          secondary: HomeColors.violetOf(context),
          surface: surface,
          onSurface: textPrimary,
        ),
        dialogTheme: base.dialogTheme.copyWith(
          backgroundColor: surface,
          shape: dialogShape,
        ),
        datePickerTheme: base.datePickerTheme.copyWith(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          headerBackgroundColor: HomeColors.violetOf(context),
          headerForegroundColor: Colors.white,
          shape: dialogShape,
          todayForegroundColor: WidgetStatePropertyAll(
            HomeColors.violetOf(context),
          ),
          dayStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        timePickerTheme: base.timePickerTheme.copyWith(
          backgroundColor: surface,
          shape: dialogShape,
          dialHandColor: HomeColors.orange,
          dialBackgroundColor: HomeColors.violetTintOf(context),
          hourMinuteColor: HomeColors.violetTintOf(context),
          hourMinuteTextColor: textPrimary,
          dayPeriodColor: HomeColors.violetOf(context),
          dayPeriodTextColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : textPrimary,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: HomeColors.orange,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: _pickerThemeBuilder,
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
      _scheduleEstimateFetch();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: _pickerThemeBuilder,
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _timePeriod = picked.period == DayPeriod.am ? 'am' : 'pm';
      });
      _scheduleEstimateFetch();
    }
  }

  void _onContinuePressed(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    if (_pickupLocation.isEmpty || _deliveryLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectPickupAndDelivery),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }
    if (_supportedVehicleTypes.isEmpty || _selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pickupOutsideDeliveryServiceArea),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }
    if (_dateController.text.isEmpty || _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.scheduleSelectDateTime),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    final scheduledDateTime = _parseScheduledDateTime();
    if (scheduledDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.scheduleInvalidDateTime),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    if (!_hasServerEstimate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.waitForEstimateBeforeContinue),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageDetailsScreen(
          pickupLocation: _pickupLocation,
          deliveryLocation: _deliveryLocation,
          pickupPosition: _pickupPosition,
          deliveryPosition: _deliveryPosition,
          selectedVehicle: _selectedVehicle!,
          isInstantDelivery: false,
          scheduledPickup: scheduledDateTime,
          scheduledDelivery: scheduledDateTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final topPad = MediaQuery.paddingOf(context).top;
          const initialSheetSize = 0.5;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            // Map is always light: keep status bar icons dark.
            value: SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
            child: Scaffold(
              backgroundColor: HomeColors.backgroundOf(context),
              body: Stack(
                children: [
                  Positioned.fill(
                    child: _buildMapOrFallback(context),
                  ),
                  Positioned(
                    top: topPad + 8,
                    left: 16,
                    child: _MapCircleButton(
                      icon: Icons.arrow_back_rounded,
                      color: HomeColors.textPrimaryOf(context),
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Positioned(
                    top: topPad + 8,
                    right: 16,
                    child: _MapCircleButton(
                      icon: Icons.my_location_rounded,
                      color: _isLoadingLocation
                          ? HomeColors.textMutedOf(context)
                          : HomeColors.violetOf(context),
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
                    ),
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: initialSheetSize,
                    minChildSize: 0.35,
                    maxChildSize: 0.85,
                    builder: (context, scrollController) {
                      final bottomInset = MediaQuery.paddingOf(context).bottom;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: HomeColors.backgroundOf(context),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x261B1530),
                              blurRadius: 24,
                              offset: Offset(0, -6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: HomeColors.textMutedOf(context)
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.courierScheduleTitle,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color:
                                            HomeColors.textPrimaryOf(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.courierScheduleSubtitle,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                        color: HomeColors.textMutedOf(context),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _LocationField(
                                      label: l10n.pickupLocationLabel,
                                      value: _isLoadingLocation
                                          ? l10n.locationGetting
                                          : (_pickupResolveFailed
                                              ? l10n.locationUnable
                                              : (_pickupLocation.isEmpty
                                                  ? l10n.tapToSelectPickup
                                                  : _pickupLocation)),
                                      isPlaceholder: _pickupLocation.isEmpty,
                                      icon: Icons.my_location_rounded,
                                      iconColor: HomeColors.orange,
                                      isReadOnly: false,
                                      onTap: _selectPickupLocation,
                                    ),
                                    _LocationField(
                                      label: l10n.deliveryLocationLabel,
                                      value: _deliveryLocation.isEmpty
                                          ? l10n.tapToSelectDelivery
                                          : _deliveryLocation,
                                      isPlaceholder: _deliveryLocation.isEmpty,
                                      icon: Icons.location_on_rounded,
                                      iconColor: HomeColors.violetOf(context),
                                      isReadOnly: false,
                                      onTap: _selectDeliveryLocation,
                                    ),
                                    const SizedBox(height: 22),
                                    _SectionTitle(
                                      icon: Icons.event_rounded,
                                      text: l10n.labelDate,
                                    ),
                                    const SizedBox(height: 10),
                                    _PickerTile(
                                      icon: Icons.calendar_month_rounded,
                                      value: _dateController.text.isEmpty
                                          ? l10n.hintDateFormat
                                          : _dateController.text,
                                      isPlaceholder:
                                          _dateController.text.isEmpty,
                                      onTap: _selectDate,
                                    ),
                                    const SizedBox(height: 18),
                                    _SectionTitle(
                                      icon: Icons.schedule_rounded,
                                      text: l10n.labelTime,
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _PickerTile(
                                            icon: Icons.access_time_rounded,
                                            value: _timeController.text.isEmpty
                                                ? l10n.hintTimeFormat
                                                : _timeController.text,
                                            isPlaceholder:
                                                _timeController.text.isEmpty,
                                            onTap: _selectTime,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _MeridiemToggle(
                                          value: _timePeriod,
                                          amLabel: l10n.meridiemAm,
                                          pmLabel: l10n.meridiemPm,
                                          onChanged: (value) {
                                            setState(() {
                                              _timePeriod = value;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    _SectionTitle(
                                      icon: Icons.local_shipping_rounded,
                                      text: l10n.vehicleType,
                                    ),
                                    const SizedBox(height: 12),
                                    if (_pickupLocation.isNotEmpty &&
                                        !_isLoadingServiceArea &&
                                        _supportedVehicleTypes.isEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: _ErrorNote(
                                          text: l10n
                                              .pickupOutsideDeliveryServiceArea,
                                        ),
                                      ),
                                    if (_supportedVehicleTypes.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            const gap = 12.0;
                                            final tileWidth =
                                                (constraints.maxWidth -
                                                        gap * 2) /
                                                    3;
                                            return Wrap(
                                              spacing: gap,
                                              runSpacing: gap,
                                              children: [
                                                for (final vehicleId
                                                    in _supportedVehicleTypes)
                                                  SizedBox(
                                                    width: tileWidth,
                                                    child: _VehicleTypeOption(
                                                      icon: courierVehicleIcon(
                                                        vehicleId,
                                                      ),
                                                      label:
                                                          courierVehicleLabel(
                                                        vehicleId,
                                                        l10n,
                                                      ),
                                                      isSelected:
                                                          _selectedVehicle ==
                                                              vehicleId,
                                                      onTap: () {
                                                        setState(() {
                                                          _selectedVehicle =
                                                              vehicleId;
                                                        });
                                                        _scheduleEstimateFetch();
                                                        _syncNearbyDrivers();
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    DeliveryEstimateBanner(
                                      isVisible: _canFetchEstimate ||
                                          _isLoadingEstimate ||
                                          _estimateError != null ||
                                          _estimatedCost != null,
                                      isLoading: _isLoadingEstimate,
                                      error: _estimateError,
                                      estimatedCost: _estimatedCost,
                                      estimatedDistance: _estimatedDistance,
                                      estimatedDuration: _estimatedDuration,
                                      currency: _estimatedCurrency,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: HomeColors.surfaceOf(context),
                                border: Border(
                                  top: BorderSide(
                                    color: HomeColors.borderOf(context),
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  12 + bottomInset,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _onContinuePressed(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HomeColors.orange,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            l10n.actionContinue,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
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
      return ColoredBox(
        color: HomeColors.backgroundOf(context),
        child: const Center(
          child: CircularProgressIndicator(color: HomeColors.orange),
        ),
      );
    }
    if (_hasGoogleMapsApiKey == false) {
      return ColoredBox(
        color: HomeColors.backgroundOf(context),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.taxiGoogleMapsNotConfigured,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
        ),
      );
    }

    final privacy = _nearbyPoller.result.privacyMessage;
    return Stack(
      children: [
        gmaps.GoogleMap(
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
                  22.0,
                ),
              ),
            if (_deliveryPosition != null)
              gmaps.Marker(
                markerId: const gmaps.MarkerId('delivery'),
                position: _toG(_deliveryPosition!),
                icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                  266.0,
                ),
              ),
            ...nearbyDriverMapMarkers(
              _nearbyPoller.result.drivers,
              iconsByAsset: _nearbyIconsByAsset,
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
                    color: HomeColors.violetOf(context),
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
            _showLocationSelectionDialog(
                LatLng(point.latitude, point.longitude));
          },
        ),
        if (privacy != null && privacy.isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Material(
              color: HomeColors.surfaceOf(context).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: HomeColors.violetOf(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        privacy,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: HomeColors.textMutedOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isReadOnly;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _LocationField({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.isReadOnly = false,
    this.isPlaceholder = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SendPackageLocationRow(
      icon: icon,
      label: label,
      accent: iconColor,
      text: value,
      isPlaceholder: isPlaceholder,
      onTap: isReadOnly ? () {} : onTap,
    );
  }
}

/// Small section heading with a leading icon (picture-first).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: HomeColors.violetOf(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tappable date / time field: tinted icon tile + value + chevron.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;

  static const _radius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    final accent = HomeColors.violetOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: _radius,
          side: BorderSide(color: HomeColors.borderOf(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: HomeColors.violetTintOf(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, size: 24, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isPlaceholder ? FontWeight.w600 : FontWeight.w800,
                        letterSpacing: isPlaceholder ? 0 : -0.2,
                        color: isPlaceholder
                            ? HomeColors.textMutedOf(context)
                            : HomeColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 24,
                    color: HomeColors.textMutedOf(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AM / PM segmented toggle.
class _MeridiemToggle extends StatelessWidget {
  const _MeridiemToggle({
    required this.value,
    required this.amLabel,
    required this.pmLabel,
    required this.onChanged,
  });

  final String value;
  final String amLabel;
  final String pmLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderOf(context)),
        boxShadow: AppColors.softShadow(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(context, 'am', amLabel),
          const SizedBox(width: 4),
          _segment(context, 'pm', pmLabel),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String id, String label) {
    final selected = value == id;
    return Material(
      color: selected ? HomeColors.violetOf(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(id),
        child: Container(
          constraints: const BoxConstraints(minWidth: 52),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : HomeColors.textMutedOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big picture-first vehicle choice tile.
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

  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final accent = HomeColors.violetOf(context);
    final tint = HomeColors.violetTintOf(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: isSelected ? const [] : AppColors.softShadow(context),
        ),
        child: Material(
          color: isSelected ? tint : HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(
              color: isSelected ? accent : HomeColors.borderOf(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? HomeColors.surfaceOf(context)
                                : tint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, size: 30, color: accent),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: HomeColors.textPrimaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round floating map control (back / my-location) with a soft shadow.
class _MapCircleButton extends StatelessWidget {
  const _MapCircleButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: CircleBorder(
          side: BorderSide(color: HomeColors.borderOf(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: tooltip,
          iconSize: 26,
          constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Soft error banner: icon tile + text.
class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.errorColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.errorColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.wrong_location_rounded,
              size: 22,
              color: AppColors.errorColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
