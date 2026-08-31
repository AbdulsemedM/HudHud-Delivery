import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/app/navigation/dashboard_navigation.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/easy_mode/voice_hint_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/widgets/call_support_button.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/easy_mode/delivery_status_sound_service.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/data/models/delivery_live_tracking.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/nearby_driver_markers.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_home_refresh.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_cancel.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_estimate.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_notification.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/features/courier/utils/nearby_drivers_poller.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'delivery_tracking_screen.dart';

class FindingCourierScreen extends StatefulWidget {
  final int? deliveryId;
  final String pickupLocation;
  final String deliveryLocation;
  final LatLng? pickupPosition;
  final LatLng? deliveryPosition;
  final String selectedVehicle;
  final String itemType;
  final String quantity;
  final String whoPays;
  final String paymentType;
  final String recipientName;
  final String recipientPhone;
  final String? packageImagePath;
  final List<LatLng>? routePolylinePoints;

  const FindingCourierScreen({
    super.key,
    this.deliveryId,
    required this.pickupLocation,
    required this.deliveryLocation,
    this.pickupPosition,
    this.deliveryPosition,
    required this.selectedVehicle,
    required this.itemType,
    required this.quantity,
    required this.whoPays,
    required this.paymentType,
    required this.recipientName,
    required this.recipientPhone,
    this.packageImagePath,
    this.routePolylinePoints,
  });

  @override
  State<FindingCourierScreen> createState() => _FindingCourierScreenState();
}

class _FindingCourierScreenState extends State<FindingCourierScreen> {
  late final CourierRepository _courierRepository;
  late final NearbyDriversPoller _nearbyPoller;

  Timer? _pollTimer;
  gmaps.GoogleMapController? _mapController;
  Map<String, gmaps.BitmapDescriptor> _nearbyIconsByAsset = {};
  List<LatLng>? _routePolylinePoints;
  bool? _hasGoogleMapsApiKey;
  bool _isCancelling = false;
  bool _hasNavigated = false;
  bool _didFocusPickup = false;
  int _pollIntervalSeconds = 10;
  String? _searchMessage;

  static const _searchingStatuses = {
    'searching',
    'pending',
    'requested',
    'looking_for_driver',
    'looking_for_courier',
    'created',
    'request_received',
    'request received',
    'pending_payment',
  };

  /// Static search rings around pickup (meters) — no per-frame rebuilds.
  static const double _searchInnerRadiusM = 220;
  static const double _searchOuterRadiusM = 480;
  static const double _pickupZoom = 14.8;
  static const int _nearbyRadiusKm = 10;
  static const double _sheetFraction = 0.36;

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final msg = context.l10n.trackingStatusSearching;
      VoiceHintService.instance.speak(msg);
      unawaited(
        DeliveryStatusSoundService.instance.playStatusChange('searching'),
      );
    });
    _nearbyPoller = NearbyDriversPoller(
      repository: _courierRepository,
      onUpdate: () => unawaited(_onNearbyDriversUpdated()),
    );

    unawaited(preloadCommonCourierVehicleMapIcons());
    _loadMapsAvailability();
    _startNearbyPoller();
    final seeded = widget.routePolylinePoints;
    // Two points are a pickup→dropoff shortcut, not a road route.
    if (seeded != null && seeded.length > 2) {
      _routePolylinePoints = seeded;
    }
    if (widget.pickupPosition != null && widget.deliveryPosition != null) {
      _fetchRouteDirections();
    }
    _pollAssignment();
    _startPollTimer();
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

  void _startNearbyPoller() {
    final pickup = widget.pickupPosition;
    if (pickup == null) return;
    _nearbyPoller.setTarget(
      latitude: pickup.latitude,
      longitude: pickup.longitude,
      vehicleType: mapCourierVehicleType(widget.selectedVehicle),
      radius: _nearbyRadiusKm,
    );
  }

  Future<void> _loadMapsAvailability() async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (!mounted) return;
    setState(() {
      _hasGoogleMapsApiKey = key.trim().isNotEmpty;
    });
  }

  Future<void> _fetchRouteDirections() async {
    final pickup = widget.pickupPosition;
    final delivery = widget.deliveryPosition;
    if (pickup == null || delivery == null) return;

    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
      if (!mounted) return;
      final result = await GoogleDirectionsService.getDirections(
        originLat: pickup.latitude,
        originLng: pickup.longitude,
        destLat: delivery.latitude,
        destLng: delivery.longitude,
      );
      if (!mounted) return;
      final points = result?.polylinePoints;
      if (points != null && points.length > 2) {
        setState(() {
          _routePolylinePoints = points;
        });
        return;
      }
    }
  }

  void _startPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: _pollIntervalSeconds),
      (_) => _pollAssignment(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _nearbyPoller.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  void _focusPickupOnce() {
    if (_didFocusPickup) return;
    final controller = _mapController;
    final pickup = widget.pickupPosition;
    if (controller == null) return;

    _didFocusPickup = true;
    if (pickup != null) {
      controller.moveCamera(
        gmaps.CameraUpdate.newLatLngZoom(_toG(pickup), _pickupZoom),
      );
      return;
    }
    final delivery = widget.deliveryPosition;
    if (delivery != null) {
      controller.moveCamera(
        gmaps.CameraUpdate.newLatLngZoom(_toG(delivery), _pickupZoom),
      );
    }
  }

  LatLng get _mapCenter =>
      widget.pickupPosition ??
      widget.deliveryPosition ??
      const LatLng(9.03, 38.74);

  Set<gmaps.Marker> get _markers {
    return {
      if (widget.pickupPosition != null)
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: _toG(widget.pickupPosition!),
          infoWindow: gmaps.InfoWindow(
            title: 'Pickup',
            snippet: widget.pickupLocation,
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
        ),
      if (widget.deliveryPosition != null)
        gmaps.Marker(
          markerId: const gmaps.MarkerId('delivery'),
          position: _toG(widget.deliveryPosition!),
          infoWindow: gmaps.InfoWindow(
            title: 'Delivery',
            snippet: widget.deliveryLocation,
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
        ),
      ...nearbyDriverMapMarkers(
        _nearbyPoller.result.drivers,
        iconsByAsset: _nearbyIconsByAsset,
      ),
    };
  }

  Set<gmaps.Polyline> get _polylines {
    final points = _routePolylinePoints;
    if (points == null || points.length < 3) return {};
    return {
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId('route'),
        points: points.map(_toG).toList(),
        color: HomeColors.violet,
        width: 4,
      ),
    };
  }

  Set<gmaps.Circle> get _searchCircles {
    final pickup = widget.pickupPosition;
    if (pickup == null) return {};
    final center = _toG(pickup);
    return {
      gmaps.Circle(
        circleId: const gmaps.CircleId('search_ring_outer'),
        center: center,
        radius: _searchOuterRadiusM,
        fillColor: HomeColors.violet.withValues(alpha: 0.08),
        strokeColor: HomeColors.violet.withValues(alpha: 0.28),
        strokeWidth: 1,
      ),
      gmaps.Circle(
        circleId: const gmaps.CircleId('search_ring_inner'),
        center: center,
        radius: _searchInnerRadiusM,
        fillColor: HomeColors.violet.withValues(alpha: 0.12),
        strokeColor: HomeColors.violet.withValues(alpha: 0.35),
        strokeWidth: 1,
      ),
    };
  }

  bool _isSearchingStatus(String? status) {
    if (status == null || status.isEmpty) return true;
    final normalized = status.toLowerCase().replaceAll(' ', '_');
    return _searchingStatuses.contains(normalized) ||
        _searchingStatuses.contains(status.toLowerCase());
  }

  bool _isAssignedFromPayload(Map<String, dynamic>? data) {
    if (data == null) return false;
    final status = resolveDeliveryStatus(data);
    if (isDeliveryAcceptedForTracking(status)) return true;
    if (_isSearchingStatus(status)) return false;
    if (data['driver'] != null || data['driver_id'] != null) {
      return !isDeliveryTerminalStatus(status);
    }
    return false;
  }

  Future<void> _pollAssignment() async {
    if (_hasNavigated || _isCancelling || !mounted) return;

    DeliveryLiveTracking? live;
    if (widget.deliveryId != null) {
      final liveResult =
          await _courierRepository.getDeliveryLiveTracking(widget.deliveryId!);
      if (liveResult['success'] == true) {
        live = liveResult['tracking'] as DeliveryLiveTracking?;
        final nextPoll = live?.pollAfterSeconds ?? 10;
        if (nextPoll != _pollIntervalSeconds && nextPoll >= 1) {
          _pollIntervalSeconds = nextPoll;
          _startPollTimer();
        }
        final message = live?.message;
        if (message != null &&
            message.isNotEmpty &&
            message != _searchMessage &&
            mounted) {
          setState(() => _searchMessage = message);
        }
        if (live?.trackingAvailable == true) {
          _openTracking();
          return;
        }
        if (_isSearchingStatus(live?.status) ||
            live?.trackingAvailable == false) {
          return;
        }
      }
    }

    Map<String, dynamic>? data;
    if (widget.deliveryId != null) {
      final track = await _courierRepository.getDeliveryTrack(widget.deliveryId!);
      if (track['success'] == true) {
        data = track['data'] as Map<String, dynamic>?;
      }
    }

    if (!_isAssignedFromPayload(data)) {
      final active = await _courierRepository.getUserActiveDelivery();
      if (active['success'] == true) {
        data = active['delivery'] as Map<String, dynamic>?;
      }
    }

    if (!mounted || _hasNavigated) return;
    if (!_isAssignedFromPayload(data)) return;

    _openTracking(
      deliveryId: widget.deliveryId ??
          (data?['id'] is int
              ? data!['id'] as int
              : int.tryParse(data?['id']?.toString() ?? '')),
    );
  }

  void _openTracking({int? deliveryId}) {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _pollTimer?.cancel();
    final id = deliveryId ?? widget.deliveryId;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryTrackingScreen(
          deliveryId: id,
          pickupLocation: widget.pickupLocation,
          deliveryLocation: widget.deliveryLocation,
          pickupPosition: widget.pickupPosition,
          deliveryPosition: widget.deliveryPosition,
          selectedVehicle: widget.selectedVehicle,
          itemType: widget.itemType,
          quantity: widget.quantity,
          whoPays: widget.whoPays,
          paymentType: widget.paymentType,
          recipientName: widget.recipientName,
          recipientPhone: widget.recipientPhone,
          packageImagePath: widget.packageImagePath,
        ),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    if (_isCancelling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cancelDeliveryTitle),
        content: Text(
          cancelDeliveryConfirmMessage(context.l10n),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.actionNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.actionYesCancel,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final deliveryId = widget.deliveryId;
    if (deliveryId == null) {
      _goToHome();
      return;
    }

    setState(() => _isCancelling = true);
    final result = await _courierRepository.cancelDelivery(
      deliveryId: deliveryId,
    );
    if (!mounted) return;

    if (result['success'] != true) {
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? "You can't cancel this delivery",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _pollTimer?.cancel();

    final refund = parseDeliveryCancelRefundResponse(result['data'] ?? result);
    final successMessage = formatDeliveryCancelMessage(refund);

    if (!mounted) return;
    setState(() => _isCancelling = false);
    CourierHomeRefresh.instance.notifyRefresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: Colors.green,
      ),
    );
    _goToHome();
  }

  void _goToHome() {
    CourierHomeRefresh.instance.notifyRefresh();
    DashboardNavigation.instance.goToHome(refreshHome: true);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final borderColor = HomeColors.borderOf(context);
          final privacy = _nearbyPoller.result.privacyMessage;
          final nearbyEmpty = _nearbyPoller.result.drivers.isEmpty;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _goToHome();
            },
            child: Scaffold(
              backgroundColor: HomeColors.backgroundOf(context),
              body: Stack(
                children: [
                  _buildMapOrFallback(context),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    left: 16,
                    child: Material(
                      color: HomeColors.surfaceElevatedOf(context),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: HomeColors.textPrimaryOf(context),
                        ),
                        onPressed: _goToHome,
                        tooltip: 'Go to home',
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    right: 16,
                    child: Material(
                      color: HomeColors.surfaceElevatedOf(context),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: const CallSupportButton(compact: true),
                    ),
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: _sheetFraction,
                    minChildSize: 0.28,
                    maxChildSize: 0.55,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: HomeColors.surfaceOf(context),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppColors.radiusLG),
                          ),
                          border: Border(
                            top: BorderSide(color: borderColor),
                            left: BorderSide(color: borderColor),
                            right: BorderSide(color: borderColor),
                          ),
                        ),
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            AppColors.spaceMD,
                            8,
                            AppColors.spaceMD,
                            AppColors.spaceMD,
                          ),
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: HomeColors.borderOf(context),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppColors.spaceMD),
                            Text(
                              context.l10n.courierFindingNearestDrivers,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: HomeColors.violet,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchMessage ??
                                  context.l10n
                                      .courierFindingNearestDriversSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: HomeColors.textMutedOf(context),
                              ),
                            ),
                            if (nearbyEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'No drivers nearby yet — still searching',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: HomeColors.textMutedOf(context),
                                ),
                              ),
                            ],
                            if (privacy != null && privacy.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                privacy,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: HomeColors.textMutedOf(context),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppColors.spaceMD),
                            const _LoadingDots(),
                            const SizedBox(height: AppColors.spaceLG),
                            SizedBox(
                              width: double.infinity,
                              height: AppColors.buttonHeightMD,
                              child: OutlinedButton(
                                onPressed:
                                    _isCancelling ? null : _cancelOrder,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.errorColor,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppColors.radiusLG,
                                    ),
                                  ),
                                ),
                                child: _isCancelling
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.errorColor,
                                        ),
                                      )
                                    : const Text(
                                        'Cancel delivery',
                                        style: TextStyle(
                                          color: AppColors.errorColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _goToHome,
                              child: Text(
                                'Go to home',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: HomeColors.violet,
                                  fontWeight: FontWeight.w600,
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
    if (_hasGoogleMapsApiKey == null) {
      return ColoredBox(
        color: HomeColors.backgroundOf(context),
        child: Center(
          child: CircularProgressIndicator(color: HomeColors.violet),
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

    final bottomPadding =
        MediaQuery.sizeOf(context).height * _sheetFraction;

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _toG(_mapCenter),
        zoom: _pickupZoom,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      markers: _markers,
      polylines: _polylines,
      circles: _searchCircles,
      onMapCreated: (controller) {
        _mapController = controller;
        _focusPickupOnce();
      },
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final opacity = (value < 0.5) ? value * 2 : (1 - value) * 2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: HomeColors.violet.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
