import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/snackbar_util.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';
import 'package:hudhud_delivery/features/taxi/data/models/ride_request_result.dart';
import 'package:hudhud_delivery/features/taxi/data/ride_data_provider.dart';
import 'package:shimmer/shimmer.dart';
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
  List<Map<String, dynamic>> _paymentMethods =
      List.from(kDefaultAllowedPaymentMethods);
  bool _loadingPaymentMethods = true;
  Map<String, dynamic> _paymentDetails = {};
  String _ebirrProvider = 'kaafi';
  bool _useHpp = false;
  bool _isLoadingEstimates = true;
  bool _isRequestingRide = false;
  String? _estimateError;
  final RideDataProvider _rideDataProvider = RideDataProvider();
  late final PaymentRepository _paymentRepository;
  List<LatLng>? _routePolylinePoints;
  double? _routeDistanceKm;
  bool _isLoadingRoute = false;
  bool? _hasGoogleMapsApiKey;

  List<TripOption> _tripOptions = [];

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _paymentRepository = PaymentRepository(
      paymentDataProvider: PaymentDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _loadMapsAvailability();
    _loadPaymentMethods();
    _selectedTrip = 'go';
    if (widget.initialRoutePolylinePoints != null &&
        widget.initialRouteDistanceKm != null) {
      _routePolylinePoints = widget.initialRoutePolylinePoints;
      _routeDistanceKm = widget.initialRouteDistanceKm;
    } else {
      _fetchRouteDirections();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEstimates();
    });
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await _paymentRepository.getPaymentMethods();
      if (!mounted) return;
      setState(() {
        _paymentMethods = methods.isNotEmpty
            ? methods
            : List.from(kDefaultAllowedPaymentMethods);
        _loadingPaymentMethods = false;
        if (!_paymentMethods.any((m) => m['id'] == _paymentMethod)) {
          _paymentMethod = _paymentMethods.first['id'] as String? ?? 'wallet';
          _paymentDetails = {};
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentMethods = List.from(kDefaultAllowedPaymentMethods);
        _loadingPaymentMethods = false;
      });
    }
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
    String? comingSoonMessage;
    for (final (id, name, imagePath, hasFasterBadge, isDiscount)
        in tripConfigs) {
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
      if (isServiceComingSoonResult(result)) {
        comingSoonMessage =
            result['errorMessage']?.toString() ?? 'Ride hailing is coming soon.';
        break;
      }
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
        if (isServiceComingSoonResult(result)) {
          comingSoonMessage = result['errorMessage']?.toString() ??
              'Ride hailing is coming soon.';
          break;
        }
      }

      if (mounted && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final fare = (data['estimated_fare'] as num?)?.toDouble() ?? 0;
        if (fare <= 0) continue;
        final duration = (data['estimated_duration'] as int?) ?? 0;
        final eta = DateTime.now().add(Duration(minutes: duration));
        final dist = (data['estimated_distance'] as num?)?.toDouble();
        options.add(TripOption(
          id: id,
          name: name,
          price: fare.round(),
          originalPrice: isDiscount ? (fare * 1.1).round() : null,
          estimatedTime: '$duration min',
          estimatedArrival:
              '${eta.hour > 12 ? eta.hour - 12 : eta.hour}:${eta.minute.toString().padLeft(2, '0')}${eta.hour >= 12 ? 'pm' : 'am'}',
          vehicleImagePath: imagePath,
          hasFasterBadge: hasFasterBadge,
          isDiscount: isDiscount,
          estimatedDistance: dist,
          estimatedDuration: duration,
          vehicleType: params.vehicleType,
          rideType: params.rideType,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _tripOptions = options;
        _isLoadingEstimates = false;
        if (comingSoonMessage != null) {
          _estimateError = comingSoonMessage;
          _selectedTrip = null;
        } else if (options.isEmpty) {
          _estimateError =
              'Could not fetch ride estimates. Please try again.';
          _selectedTrip = null;
        } else {
          _estimateError = null;
          if (_selectedTrip == null ||
              !options.any((o) => o.id == _selectedTrip)) {
            _selectedTrip = options.first.id;
          }
        }
      });
    }
  }

  Future<void> _onSelectTrip(TripOption selectedOption) async {
    if (_isRequestingRide || selectedOption.price <= 0) return;

    if (paymentMethodNeedsDetailsForm(_paymentMethod)) {
      final phoneError = validatePaymentPhone(
        _paymentDetails['phone']?.toString(),
        _paymentMethod,
      );
      if (phoneError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(phoneError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

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

    if (result['statusCode'] != null &&
        result['statusCode'] >= 200 &&
        result['statusCode']! < 300) {
      final parsed = parseRideRequestResponse(result['data']);
      final rideId = parsed.isValid ? parsed.rideId : null;
      final price = (parsed.estimatedFare ?? selectedOption.price.toDouble())
          .round();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindingDriverScreen(
            pickupLocation: widget.pickupLocation,
            destinationLocation: widget.destinationLocation,
            pickupAddress: widget.pickupAddress,
            destinationAddress: widget.destinationAddress,
            tripType: selectedOption.name,
            price: price,
            paymentMethod: _paymentMethod,
            rideId: rideId,
            currency: parsed.currency ?? 'KES',
            paymentDetails: Map<String, dynamic>.from(_paymentDetails),
          ),
        ),
      );
    } else if (isServiceComingSoonResult(result)) {
      SnackbarUtil.showComingSoon(
        context,
        result['errorMessage']?.toString() ?? 'Ride hailing is coming soon.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['errorMessage'] ?? 'Failed to request ride'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Color _cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : AppColors.lightBorder;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final borderColor = _cardBorder(context);
    TripOption? selectedOption;
    for (final opt in _tripOptions) {
      if (opt.id == _selectedTrip) {
        selectedOption = opt;
        break;
      }
    }
    selectedOption ??= _tripOptions.isNotEmpty ? _tripOptions.first : null;
    final canConfirm = !_isLoadingEstimates &&
        !_isRequestingRide &&
        selectedOption != null &&
        selectedOption.price > 0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMapOrFallback(context),
          ),
          Positioned(
            top: 48,
            left: AppColors.spaceMD,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.52,
            minChildSize: 0.38,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppColors.radiusXL),
                    topRight: Radius.circular(AppColors.radiusXL),
                  ),
                  border: Border(
                    top: BorderSide(color: borderColor),
                    left: BorderSide(color: borderColor),
                    right: BorderSide(color: borderColor),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: AppColors.spaceSM),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppColors.spaceMD),
                    if (_routeDistanceKm != null || _isLoadingRoute)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppColors.spaceMD,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.straighten_rounded,
                              size: 18,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: AppColors.spaceSM),
                            if (_isLoadingRoute)
                              const _InlineShimmer(width: 72, height: 14)
                            else if (_routeDistanceKm != null)
                              Text(
                                l10n.taxiDistanceKm(
                                  _routeDistanceKm!.toStringAsFixed(2),
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (_routeDistanceKm != null || _isLoadingRoute)
                      const SizedBox(height: AppColors.spaceMD),
                    if (!_isLoadingRoute && _routePolylinePoints == null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppColors.spaceMD,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppColors.spaceMD),
                          decoration: BoxDecoration(
                            color: AppColors.warningColor.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusLG),
                            border: Border.all(
                              color: AppColors.warningColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.warningDarkColor,
                              ),
                              const SizedBox(width: AppColors.spaceSM),
                              Expanded(
                                child: Text(
                                  'Road route unavailable. Enable "Directions API" in Google Cloud Console for your API key (see MAPS_SETUP.md).',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.warningDarkColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppColors.spaceMD),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.spaceMD,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Choose a trip',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (_estimateError != null) ...[
                      const SizedBox(height: AppColors.spaceSM),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppColors.spaceMD,
                        ),
                        child: Text(
                          _estimateError!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.warningDarkColor,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppColors.spaceMD),
                    Expanded(
                      child: _isLoadingEstimates
                          ? _TripOptionsShimmer(borderColor: borderColor)
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppColors.spaceMD,
                              ),
                              itemCount: _tripOptions.length,
                              itemBuilder: (context, index) {
                                final option = _tripOptions[index];
                                final isSelected = _selectedTrip == option.id;

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppColors.spaceMD,
                                  ),
                                  child: _TripOptionCard(
                                    option: option,
                                    isSelected: isSelected,
                                    borderColor: borderColor,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.spaceMD,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.labelPaymentMethod,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppColors.spaceSM),
                          if (_loadingPaymentMethods)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _paymentMethods.map((method) {
                                final id = method['id'] as String? ?? '';
                                final name =
                                    method['name'] as String? ?? id;
                                final isSelected = _paymentMethod == id;
                                return FilterChip(
                                  label: Text(name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _paymentMethod = id;
                                        _paymentDetails = {};
                                        _useHpp = false;
                                        _ebirrProvider = 'kaafi';
                                      });
                                    }
                                  },
                                  showCheckmark: false,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  backgroundColor: colorScheme.surface,
                                  selectedColor: AppColors.primaryColor,
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : borderColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppColors.radiusFull,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          PaymentDetailsForm(
                            key: ValueKey(_paymentMethod),
                            paymentMethodCode: _paymentMethod,
                            ebirrProvider: _ebirrProvider,
                            useHpp: _useHpp,
                            onEbirrProviderChanged: (v) =>
                                setState(() => _ebirrProvider = v),
                            onUseHppChanged: (v) =>
                                setState(() => _useHpp = v),
                            onChanged: (details) {
                              _paymentDetails = details;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppColors.spaceMD),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.spaceMD,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: AppColors.buttonHeightMD,
                        child: FilledButton(
                          onPressed: canConfirm
                              ? () => _onSelectTrip(selectedOption!)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusLG),
                            ),
                          ),
                          child: _isRequestingRide
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  selectedOption != null
                                      ? 'Select ${selectedOption.name}'
                                      : 'Select trip',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppColors.spaceMD),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapOrFallback(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (_hasGoogleMapsApiKey == null) {
      return _MapShimmer();
    }
    if (_hasGoogleMapsApiKey == false) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppColors.spaceLG),
          child: Text(
            l10n.taxiGoogleMapsNotConfigured,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
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
          points: _routePolylinePoints != null &&
                  _routePolylinePoints!.length >= 2
              ? _routePolylinePoints!.map(_toG).toList()
              : [
                  _toG(widget.pickupLocation),
                  _toG(widget.destinationLocation),
                ],
          color: AppColors.primaryColor,
          width: 4,
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
  final Color borderColor;
  final VoidCallback onTap;

  const _TripOptionCard({
    required this.option,
    required this.isSelected,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusLG),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : borderColor,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? AppColors.primaryColor.withValues(alpha: 0.04)
                : colorScheme.surface,
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppColors.radiusMD),
                  border: Border.all(color: borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppColors.radiusMD),
                  child: Image.asset(
                    option.vehicleImagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        option.id == 'tuk'
                            ? Icons.moped_rounded
                            : Icons.directions_car_rounded,
                        size: 40,
                        color: AppColors.primaryColor,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppColors.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            option.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (option.hasFasterBadge) ...[
                          const SizedBox(width: AppColors.spaceSM),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.infoColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppColors.radiusFull),
                              border: Border.all(
                                color: AppColors.infoColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  size: 12,
                                  color: AppColors.infoColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Faster',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.infoColor,
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (option.isDiscount && option.originalPrice != null) ...[
                    Text(
                      'ETB ${option.originalPrice}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ETB ${option.price}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.successColor,
                      ),
                    ),
                  ] else
                    Text(
                      'ETB ${option.price}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primaryColor
                            : colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripOptionsShimmer extends StatelessWidget {
  final Color borderColor;

  const _TripOptionsShimmer({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder;
    final highlightColor =
        isDark ? AppColors.darkBorder : AppColors.lightInputFill;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppColors.spaceMD),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
                border: Border.all(color: borderColor),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InlineShimmer extends StatelessWidget {
  final double width;
  final double height;

  const _InlineShimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder;
    final highlightColor =
        isDark ? AppColors.darkBorder : AppColors.lightInputFill;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _MapShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder;
    final highlightColor =
        isDark ? AppColors.darkBorder : AppColors.lightInputFill;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(color: baseColor),
    );
  }
}
