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
import 'package:hudhud_delivery/features/courier/presentation/widgets/courier_vehicle_estimate_card.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/nearby_driver_markers.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/send_package_location_row.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_vehicle_display.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_estimate.dart';
import 'package:hudhud_delivery/features/courier/utils/fetch_courier_vehicle_estimates.dart';
import 'package:hudhud_delivery/features/courier/utils/nearby_drivers_poller.dart';
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
  late final CourierRepository _courierRepository;
  late final NearbyDriversPoller _nearbyPoller;
  Timer? _estimateDebounce;
  Timer? _serviceAreaDebounce;
  String _pickupLocation = '';
  String _deliveryLocation = '';
  bool _pickupResolveFailed = false;
  String? _selectedVehicle;

  /// Default map center (Addis Ababa) — same as taxi / location flows until GPS resolves.
  LatLng _currentPosition = const LatLng(9.0222, 38.7468);
  LatLng? _pickupPosition;
  LatLng? _deliveryPosition;
  bool _isLoadingLocation = true;
  List<LatLng>? _routePolylinePoints;
  bool? _hasGoogleMapsApiKey;
  bool _isLoadingEstimate = false;
  bool _isLoadingServiceArea = false;
  Map<String, DeliveryEstimate> _vehicleEstimates = {};
  List<String> _supportedVehicleTypes = const [];
  Map<String, gmaps.BitmapDescriptor> _nearbyIconsByAsset = {};

  bool get _canFetchEstimate =>
      _pickupPosition != null && _deliveryPosition != null;

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

  @override
  void dispose() {
    _estimateDebounce?.cancel();
    _serviceAreaDebounce?.cancel();
    _nearbyPoller.dispose();
    super.dispose();
  }

  void _scheduleServiceAreaFetch() {
    _serviceAreaDebounce?.cancel();
    if (_pickupLocation.trim().isEmpty) {
      setState(() {
        _isLoadingServiceArea = false;
        _supportedVehicleTypes = const [];
        _selectedVehicle = null;
        _vehicleEstimates = {};
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
    if (!_canFetchEstimate || _supportedVehicleTypes.isEmpty) {
      setState(() {
        _isLoadingEstimate = false;
        _vehicleEstimates = {};
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
        _supportedVehicleTypes.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingEstimate = true;
    });

    var cityVehicleUnsupported = false;
    var pickupAreaUnavailable = false;
    final result = await fetchCourierEstimatesForVehicles(
      vehicleIds: _supportedVehicleTypes,
      estimateForVehicle: (vehicleId) async {
        final raw = await _courierRepository.estimateDelivery(
          packageType: kCourierEstimatePlaceholderPackageType,
          packageWeight: kCourierEstimatePlaceholderWeightKg,
          pickupLatitude: _pickupPosition!.latitude,
          pickupLongitude: _pickupPosition!.longitude,
          dropoffLatitude: _deliveryPosition!.latitude,
          dropoffLongitude: _deliveryPosition!.longitude,
          vehicleType: mapCourierVehicleType(vehicleId),
          serviceType: deliveryServiceType(isInstantDelivery: true),
          pickupLocation: _pickupLocation,
        );
        final error = raw['error'] as ApiErrorResult?;
        if (error?.isCityVehicleNotSupported == true) {
          cityVehicleUnsupported = true;
        }
        if (error?.isPickupServiceAreaUnavailable == true) {
          pickupAreaUnavailable = true;
        }
        return raw;
      },
    );

    if (!mounted) return;
    setState(() {
      _isLoadingEstimate = false;
      _vehicleEstimates = result.byVehicle;
    });
    if (pickupAreaUnavailable) {
      setState(() {
        _supportedVehicleTypes = const [];
        _selectedVehicle = null;
        _vehicleEstimates = {};
      });
      return;
    }
    if (cityVehicleUnsupported) {
      await _fetchServiceArea(quoteAfter: false);
      return;
    }
    _syncNearbyDrivers();
  }

  int? _etaMinutesFor(String vehicleId) {
    if (vehicleId == _selectedVehicle) {
      int? nearest;
      for (final driver in _nearbyPoller.result.drivers) {
        final minutes = driver.estimatedPickupMinutes;
        if (minutes == null) continue;
        if (nearest == null || minutes < nearest) nearest = minutes;
      }
      if (nearest != null) return nearest;
    }
    return _vehicleEstimates[vehicleId]?.estimatedDuration;
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

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final theme = Theme.of(context);
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
                    minChildSize: 0.38,
                    maxChildSize: 0.85,
                    builder: (context, scrollController) {
                      final pickupText = _isLoadingLocation
                          ? l10n.locationGetting
                          : (_pickupResolveFailed
                              ? l10n.locationUnable
                              : (_pickupLocation.isEmpty
                                  ? l10n.tapToSelectPickup
                                  : _pickupLocation));
                      final dropoffEmpty = _deliveryLocation.isEmpty;
                      final canContinue = _pickupLocation.isNotEmpty &&
                          _deliveryLocation.isNotEmpty &&
                          _supportedVehicleTypes.isNotEmpty &&
                          _selectedVehicle != null;
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
                              child: ListView(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 12),
                                children: [
                                  Text(
                                    l10n.sendAPackageTitle,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color:
                                              HomeColors.textPrimaryOf(context),
                                          letterSpacing: -0.5,
                                        ) ??
                                        TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                          color:
                                              HomeColors.textPrimaryOf(context),
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  SendPackageLocationRow(
                                    icon: Icons.my_location_rounded,
                                    label: l10n.pickupLocationLabel,
                                    accent: HomeColors.orange,
                                    text: pickupText,
                                    isPlaceholder: _pickupLocation.isEmpty,
                                    onTap: _selectPickupLocation,
                                  ),
                                  SendPackageLocationRow(
                                    icon: Icons.location_on_rounded,
                                    label: l10n.deliveryLocationLabel,
                                    accent: HomeColors.violetOf(context),
                                    text: dropoffEmpty
                                        ? l10n.courierDeliveryAddressPlaceholder
                                        : _deliveryLocation,
                                    isPlaceholder: dropoffEmpty,
                                    onTap: _selectDeliveryLocation,
                                  ),
                                  const SizedBox(height: 18),
                                  if (_pickupLocation.isNotEmpty &&
                                      !_isLoadingServiceArea &&
                                      _supportedVehicleTypes.isEmpty) ...[
                                    _ErrorNote(
                                      text:
                                          l10n.pickupOutsideDeliveryServiceArea,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (_supportedVehicleTypes.isNotEmpty)
                                    SizedBox(
                                      height:
                                          CourierVehicleEstimateCard.height +
                                              16,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        clipBehavior: Clip.none,
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        itemCount:
                                            _supportedVehicleTypes.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          final vehicleId =
                                              _supportedVehicleTypes[index];
                                          return CourierVehicleEstimateCard(
                                            icon: courierVehicleIcon(vehicleId),
                                            label: courierVehicleLabel(
                                              vehicleId,
                                              l10n,
                                            ),
                                            isSelected:
                                                _selectedVehicle == vehicleId,
                                            isLoading: (_isLoadingEstimate ||
                                                    _isLoadingServiceArea) &&
                                                _canFetchEstimate,
                                            estimate:
                                                _vehicleEstimates[vehicleId],
                                            etaMinutes: _isLoadingEstimate
                                                ? null
                                                : _etaMinutesFor(vehicleId),
                                            onTap: () {
                                              setState(() {
                                                _selectedVehicle = vehicleId;
                                              });
                                              _syncNearbyDrivers();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                ],
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
                                    onPressed: canContinue
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PackageDetailsScreen(
                                                  pickupLocation:
                                                      _pickupLocation,
                                                  deliveryLocation:
                                                      _deliveryLocation,
                                                  pickupPosition:
                                                      _pickupPosition,
                                                  deliveryPosition:
                                                      _deliveryPosition,
                                                  selectedVehicle:
                                                      _selectedVehicle!,
                                                  isInstantDelivery: true,
                                                  scheduledPickup: null,
                                                  scheduledDelivery: null,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HomeColors.orange,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      disabledBackgroundColor:
                                          HomeColors.surfaceElevatedOf(context),
                                      disabledForegroundColor:
                                          HomeColors.textMutedOf(context),
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
                                            l10n.addInfoAboutDelivery,
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
                leading: const Icon(
                  Icons.my_location_rounded,
                  color: HomeColors.orange,
                ),
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
                leading: Icon(
                  Icons.location_on_rounded,
                  color: HomeColors.violetOf(dialogContext),
                ),
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
              context.l10n.taxiGoogleMapsNotConfigured,
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
              LatLng(point.latitude, point.longitude),
            );
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
