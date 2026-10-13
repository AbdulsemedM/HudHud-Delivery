import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/core/easy_mode/voice_hint_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/call_support_button.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/courier/easy_mode/delivery_status_sound_service.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/models/delivery_live_tracking.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/driver_contact_card.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/nearby_driver_markers.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_notification.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_navigation.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import '../../../home/presentation/widgets/home_widget.dart';

class DeliveryTrackingScreen extends StatefulWidget {
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

  const DeliveryTrackingScreen({
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
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  gmaps.GoogleMapController? _mapController;
  LatLng? _vehiclePosition;
  Timer? _pollTimer;
  gmaps.BitmapDescriptor? _deliveryGuyIcon;

  Map<String, dynamic>? _trackData;
  DeliveryLiveTracking? _liveTracking;
  GeoPoint? _retainedDriverPoint;
  bool _trackingAvailable = false;
  bool _stopPolling = false;
  int _pollIntervalSeconds = 7;
  bool _isLoadingTrack = true;
  String? _trackError;
  List<LatLng>? _routePolylinePoints;
  GeoPoint? _lastRouteOrigin;
  GeoPoint? _lastRouteDestination;

  late final CourierRepository _courierRepository;

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _loadDeliveryGuyIcon();

    if (widget.pickupPosition != null && widget.deliveryPosition != null) {
      _fetchRouteDirections(
        origin: GeoPoint(
          latitude: widget.pickupPosition!.latitude,
          longitude: widget.pickupPosition!.longitude,
        ),
        destination: GeoPoint(
          latitude: widget.deliveryPosition!.latitude,
          longitude: widget.deliveryPosition!.longitude,
        ),
      );
    }

    if (widget.deliveryId != null) {
      _fetchTrackData();
      _startPollTimer();
    } else {
      _isLoadingTrack = false;
    }
  }

  Future<void> _loadDeliveryGuyIcon() async {
    final icon = await loadDeliveryGuyMapIcon();
    if (!mounted || icon == null) return;
    setState(() => _deliveryGuyIcon = icon);
  }

  String _friendlyStatus(BuildContext context, String raw) {
    final l10n = context.l10n;
    final key = raw.toLowerCase();
    if (key.contains('search') ||
        key.contains('pending') ||
        key.contains('finding') ||
        key.contains('requested')) {
      return l10n.trackingStatusSearching;
    }
    if (key.contains('arriv') || key.contains('pickup')) {
      return l10n.trackingStatusArrived;
    }
    if (key.contains('deliver') &&
        (key.contains('ed') ||
            key.contains('complete') ||
            key.contains('done'))) {
      return l10n.trackingStatusDone;
    }
    if (key.contains('complete') ||
        key.contains('done') ||
        key.contains('finish')) {
      return l10n.trackingStatusDone;
    }
    return l10n.trackingStatusOnTheWay;
  }

  IconData _statusIcon(String raw) {
    final key = raw.toLowerCase();
    if (key.contains('search') ||
        key.contains('pending') ||
        key.contains('finding') ||
        key.contains('requested')) {
      return Icons.search_rounded;
    }
    if (key.contains('arriv') || key.contains('pickup')) {
      return Icons.place_rounded;
    }
    if (key.contains('complete') ||
        key.contains('done') ||
        key.contains('finish') ||
        (key.contains('deliver') && key.contains('ed'))) {
      return Icons.check_circle_rounded;
    }
    return Icons.delivery_dining_rounded;
  }

  void _startPollTimer() {
    _pollTimer?.cancel();
    if (_stopPolling) return;
    _pollTimer = Timer.periodic(
      Duration(seconds: _pollIntervalSeconds),
      (_) => _fetchTrackData(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  LatLng? _parseDriverLocation(Map<String, dynamic>? data) {
    if (data == null) return null;

    LatLng? fromCoords(dynamic lat, dynamic lng) {
      final latitude = double.tryParse(lat?.toString() ?? '');
      final longitude = double.tryParse(lng?.toString() ?? '');
      if (latitude == null || longitude == null) return null;
      return LatLng(latitude, longitude);
    }

    final direct = fromCoords(
      data['current_latitude'] ?? data['driver_latitude'] ?? data['latitude'],
      data['current_longitude'] ??
          data['driver_longitude'] ??
          data['longitude'],
    );
    if (direct != null) return direct;

    final driverLocation = data['driver_location'];
    if (driverLocation is Map) {
      final nested = fromCoords(
        driverLocation['latitude'] ?? driverLocation['lat'],
        driverLocation['longitude'] ?? driverLocation['lng'],
      );
      if (nested != null) return nested;
    }

    final driver = data['driver'];
    if (driver is Map) {
      return fromCoords(
        driver['latitude'] ?? driver['lat'] ?? driver['current_latitude'],
        driver['longitude'] ?? driver['lng'] ?? driver['current_longitude'],
      );
    }
    return null;
  }

  Future<void> _messageDriver() async {
    final deliveryId = widget.deliveryId;
    if (deliveryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.chatMissingDeliveryId),
        ),
      );
      return;
    }
    await openPackageDeliveryChat(context, deliveryId);
  }

  String? _driverPhone() {
    final livePhone = _liveTracking?.driver?.phone?.trim();
    if (livePhone != null && livePhone.isNotEmpty) return livePhone;

    final driver = _trackData?['driver'];
    if (driver is Map) {
      final phone = driver['phone']?.toString().trim();
      if (phone != null && phone.isNotEmpty) return phone;
    }
    return null;
  }

  Future<void> _callDriver() async {
    final phone = _driverPhone();
    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver phone number is unavailable')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone dialer')),
      );
    }
  }

  Future<void> _fetchRouteDirections({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    final same = _lastRouteOrigin != null &&
        _lastRouteDestination != null &&
        _lastRouteOrigin!.latitude == origin.latitude &&
        _lastRouteOrigin!.longitude == origin.longitude &&
        _lastRouteDestination!.latitude == destination.latitude &&
        _lastRouteDestination!.longitude == destination.longitude;
    if (same && _routePolylinePoints != null) return;

    _lastRouteOrigin = origin;
    _lastRouteDestination = destination;
    final result = await GoogleDirectionsService.getDirections(
      originLat: origin.latitude,
      originLng: origin.longitude,
      destLat: destination.latitude,
      destLng: destination.longitude,
    );
    if (!mounted) return;
    setState(() {
      _routePolylinePoints = result?.polylinePoints;
    });
  }

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  void _fitBounds() {
    if (widget.pickupPosition != null && widget.deliveryPosition != null) {
      final bounds = gmaps.LatLngBounds(
        southwest: gmaps.LatLng(
          widget.pickupPosition!.latitude < widget.deliveryPosition!.latitude
              ? widget.pickupPosition!.latitude
              : widget.deliveryPosition!.latitude,
          widget.pickupPosition!.longitude < widget.deliveryPosition!.longitude
              ? widget.pickupPosition!.longitude
              : widget.deliveryPosition!.longitude,
        ),
        northeast: gmaps.LatLng(
          widget.pickupPosition!.latitude > widget.deliveryPosition!.latitude
              ? widget.pickupPosition!.latitude
              : widget.deliveryPosition!.latitude,
          widget.pickupPosition!.longitude > widget.deliveryPosition!.longitude
              ? widget.pickupPosition!.longitude
              : widget.deliveryPosition!.longitude,
        ),
      );
      _mapController?.moveCamera(
        gmaps.CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  Future<void> _fetchTrackData() async {
    if (widget.deliveryId == null || _stopPolling) return;
    try {
      final liveResult =
          await _courierRepository.getDeliveryLiveTracking(widget.deliveryId!);
      if (!mounted) return;

      if (liveResult['notFound'] == true) {
        _stopPolling = true;
        _pollTimer?.cancel();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        return;
      }

      if (liveResult['success'] == true) {
        final live = liveResult['tracking'] as DeliveryLiveTracking?;
        await _applyLiveTracking(live);
        return;
      }

      final result =
          await _courierRepository.getDeliveryTrack(widget.deliveryId!);
      if (!mounted) return;
      setState(() {
        _isLoadingTrack = false;
        if (result['success'] == true) {
          _trackData = result['data'] as Map<String, dynamic>?;
          final parsed = _parseDriverLocation(_trackData);
          if (parsed != null) {
            _vehiclePosition = parsed;
            _retainedDriverPoint = GeoPoint(
              latitude: parsed.latitude,
              longitude: parsed.longitude,
            );
          }
          if (_trackData?['driver'] != null) {
            _trackingAvailable = true;
          }
          _trackError = null;
          final statusKey = resolveDeliveryStatus(_trackData);
          if (statusKey != null) {
            unawaited(
              DeliveryStatusSoundService.instance.playStatusChange(statusKey),
            );
          }
        } else {
          _trackError = result['message'] as String?;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTrack = false;
          _trackError = 'Failed to load tracking';
        });
      }
    }
  }

  Future<void> _applyLiveTracking(DeliveryLiveTracking? live) async {
    if (live == null || !mounted) return;

    final retained = retainDriverLocation(
      previous: _retainedDriverPoint,
      incoming: live.driverLocation,
    );
    final nextPoll = live.pollAfterSeconds < 1 ? 7 : live.pollAfterSeconds;
    final intervalChanged = nextPoll != _pollIntervalSeconds;
    _pollIntervalSeconds = nextPoll;

    final terminal = isDeliveryTerminalStatus(live.status);
    if (terminal) {
      _stopPolling = true;
      _pollTimer?.cancel();
    }

    setState(() {
      _isLoadingTrack = false;
      _liveTracking = live;
      _trackingAvailable = live.trackingAvailable;
      _retainedDriverPoint = retained;
      if (retained != null) {
        _vehiclePosition = LatLng(retained.latitude, retained.longitude);
      }
      _trackError = null;
      _trackData = {
        ...?_trackData,
        'status': live.status,
        if (live.trackingAvailable && live.driver != null)
          'driver': {
            'id': live.driver!.id,
            'name': live.driver!.name,
            'phone': live.driver!.phone,
            'vehicle_type': live.driver!.vehicleType,
            'vehicle_color': live.driver!.vehicleColor,
            'vehicle_plate_number': live.driver!.vehiclePlateNumber,
            'rating': live.driver!.rating,
          }
        else
          'driver': null,
        'estimated_arrival_minutes': live.estimatedArrivalMinutes,
      };
    });

    if (intervalChanged && !_stopPolling) {
      _startPollTimer();
    }

    final origin = live.routeOrigin ?? retained;
    GeoPoint? destination = live.routeDestination ?? live.destination;
    if (destination == null) {
      final label = live.effectiveDestinationLabel;
      final fallback =
          label == 'dropoff' ? widget.deliveryPosition : widget.pickupPosition;
      if (fallback != null) {
        destination = GeoPoint(
          latitude: fallback.latitude,
          longitude: fallback.longitude,
        );
      }
    }
    if (origin != null && destination != null) {
      await _fetchRouteDirections(origin: origin, destination: destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate center point for map
    LatLng mapCenter = const LatLng(9.0222, 38.7468);
    if (widget.pickupPosition != null && widget.deliveryPosition != null) {
      mapCenter = LatLng(
        (widget.pickupPosition!.latitude + widget.deliveryPosition!.latitude) /
            2,
        (widget.pickupPosition!.longitude +
                widget.deliveryPosition!.longitude) /
            2,
      );
    } else if (widget.pickupPosition != null) {
      mapCenter = widget.pickupPosition!;
    } else if (widget.deliveryPosition != null) {
      mapCenter = widget.deliveryPosition!;
    }

    final Set<gmaps.Marker> markers = {};
    if (widget.pickupPosition != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: _toG(widget.pickupPosition!),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            22.0,
          ),
        ),
      );
    }
    if (_vehiclePosition != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('vehicle'),
          position: _toG(_vehiclePosition!),
          icon: _deliveryGuyIcon ??
              gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueViolet,
              ),
        ),
      );
    }
    if (widget.deliveryPosition != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('delivery'),
          position: _toG(widget.deliveryPosition!),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            266.0,
          ),
        ),
      );
    }

    Set<gmaps.Polyline> polylines = {};
    final routeStart = _lastRouteOrigin != null
        ? LatLng(_lastRouteOrigin!.latitude, _lastRouteOrigin!.longitude)
        : _vehiclePosition ?? widget.pickupPosition;
    final routeEnd = _lastRouteDestination != null
        ? LatLng(
            _lastRouteDestination!.latitude,
            _lastRouteDestination!.longitude,
          )
        : (_liveTracking?.effectiveDestinationLabel == 'dropoff'
            ? widget.deliveryPosition
            : widget.pickupPosition ?? widget.deliveryPosition);
    if (routeStart != null && routeEnd != null) {
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          points:
              _routePolylinePoints != null && _routePolylinePoints!.length >= 2
                  ? _routePolylinePoints!.map(_toG).toList()
                  : [_toG(routeStart), _toG(routeEnd)],
          color: HomeColors.violetOf(context),
          width: 4,
        ),
      );
    }

    final statusText = resolveDeliveryStatusLabel(
      _trackData,
      fallback: 'in_progress',
    );
    final friendlyStatus = _friendlyStatus(context, statusText);
    final statusIcon = _statusIcon(statusText);
    final pickupLabel =
        _trackData?['pickup_location']?.toString() ?? widget.pickupLocation;
    final etaMinutes = _etaMinutes();
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final dark = HomeColors.isDark(context);
          final borderColor = HomeColors.borderOf(context);
          final topInset = MediaQuery.paddingOf(context).top + 10;
          final hasDriver = _trackingAvailable &&
              (_liveTracking?.driver != null || _trackData?['driver'] != null);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            // Map is always light: keep status bar icons dark.
            value: SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
            child: Scaffold(
              backgroundColor: HomeColors.backgroundOf(context),
              body: Stack(
                children: [
                  gmaps.GoogleMap(
                    initialCameraPosition: gmaps.CameraPosition(
                      target: _toG(mapCenter),
                      zoom: 13.0,
                    ),
                    markers: markers,
                    polylines: polylines,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitBounds();
                    },
                  ),
                  // Back
                  Positioned(
                    top: topInset,
                    left: 16,
                    child: _MapCircleButton(
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 26,
                          color: HomeColors.textPrimaryOf(context),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Call support
                  Positioned(
                    top: topInset,
                    right: 16,
                    child: const _MapCircleButton(
                      child: CallSupportButton(compact: true),
                    ),
                  ),
                  if (!_isLoadingTrack &&
                      _trackError == null &&
                      !_trackingAvailable)
                    Positioned(
                      top: topInset + 64,
                      left: 16,
                      right: 16,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppColors.softShadow(context),
                        ),
                        child: Material(
                          color: HomeColors.surfaceOf(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: dark
                                ? BorderSide(color: borderColor)
                                : BorderSide.none,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: HomeColors.isDark(context)
                                        ? AppColors.orangeTintDark
                                        : AppColors.orangeTint,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.radar_rounded,
                                    size: 22,
                                    color: AppColors.brandOrange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _liveTracking?.message ??
                                        context
                                            .l10n.courierFindingNearestDrivers,
                                    style: TextStyle(
                                      color: HomeColors.textPrimaryOf(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Bottom sheet
                  DraggableScrollableSheet(
                    initialChildSize: 0.5,
                    minChildSize: 0.35,
                    maxChildSize: 0.85,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: HomeColors.backgroundOf(context),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          border: dark
                              ? Border(
                                  top: BorderSide(color: borderColor),
                                  left: BorderSide(color: borderColor),
                                  right: BorderSide(color: borderColor),
                                )
                              : null,
                          boxShadow: dark
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Color(0x1A1B1530),
                                    blurRadius: 24,
                                    offset: Offset(0, -6),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            // Drag handle
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: borderColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            // Current status header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: dark
                                          ? AppColors.orangeTintDark
                                          : AppColors.orangeTint,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      statusIcon,
                                      color: AppColors.brandOrange,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          friendlyStatus,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: HomeColors.textPrimaryOf(
                                              context,
                                            ),
                                            fontSize: 20,
                                            height: 1.2,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          pickupLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: HomeColors.textMutedOf(
                                              context,
                                            ),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            StatusChip(status: statusText),
                                            if (etaMinutes != null)
                                              _EtaPill(
                                                label: context.l10n
                                                    .courierEstimateMinutes(
                                                  etaMinutes,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: HomeColors.violetTintOf(context),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: IconButton(
                                      tooltip: context.l10n.easySpeakHint,
                                      iconSize: 26,
                                      constraints: const BoxConstraints(
                                        minWidth: 52,
                                        minHeight: 52,
                                      ),
                                      icon: Icon(
                                        Icons.volume_up_rounded,
                                        color: HomeColors.violetOf(context),
                                      ),
                                      onPressed: () {
                                        VoiceHintService.instance.speak(
                                          friendlyStatus,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Content
                            Expanded(
                              child: _isLoadingTrack
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.all(AppColors.spaceMD),
                                      child: ShimmerListView(itemCount: 3),
                                    )
                                  : _trackError != null
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 72,
                                                  height: 72,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.errorColor
                                                        .withValues(
                                                      alpha: dark ? 0.2 : 0.1,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.wifi_off_rounded,
                                                    size: 34,
                                                    color: AppColors.errorColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  _trackError!,
                                                  style: TextStyle(
                                                    color:
                                                        HomeColors.textMutedOf(
                                                      context,
                                                    ),
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : SingleChildScrollView(
                                          controller: scrollController,
                                          padding: EdgeInsets.fromLTRB(
                                            16,
                                            8,
                                            16,
                                            24 +
                                                MediaQuery.paddingOf(
                                                  context,
                                                ).bottom,
                                          ),
                                          child: Column(
                                            children: [
                                              if (hasDriver) ...[
                                                DriverContactCard(
                                                  driverName: _driverName(),
                                                  vehicle: _driverVehicle(),
                                                  rating: _driverRating(),
                                                  details: [
                                                    _liveTracking?.driver
                                                        ?.vehiclePlateNumber,
                                                    _driverPhone(),
                                                  ]
                                                      .whereType<String>()
                                                      .where(
                                                        (s) => s.isNotEmpty,
                                                      )
                                                      .join(' · '),
                                                  borderColor: borderColor,
                                                  onCall: _driverPhone() != null
                                                      ? _callDriver
                                                      : null,
                                                  onMessage: _messageDriver,
                                                ),
                                                const SizedBox(height: 14),
                                              ],
                                              _ReviewOrderCard(
                                                courierNumber: _trackData?[
                                                            'tracking_number']
                                                        ?.toString() ??
                                                    (widget.deliveryId != null
                                                        ? '#DEL-${widget.deliveryId}'
                                                        : '—'),
                                                from: _trackData?[
                                                            'pickup_location']
                                                        ?.toString() ??
                                                    widget.pickupLocation,
                                                to: _trackData?[
                                                            'dropoff_location']
                                                        ?.toString() ??
                                                    widget.deliveryLocation,
                                                createdDate:
                                                    _trackData?['created_at']
                                                            ?.toString() ??
                                                        '—',
                                                borderColor: borderColor,
                                              ),
                                              const SizedBox(height: 14),
                                              _TrackingOrderCard(
                                                timeline: _timeline(),
                                                borderColor: borderColor,
                                              ),
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
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic>? get _driverMap {
    final driver = _trackData?['driver'];
    return driver is Map<String, dynamic> ? driver : null;
  }

  String _driverName() {
    final live = _liveTracking?.driver?.name;
    if (live != null) return live;
    final map = _driverMap;
    if (map != null) return map['name']?.toString() ?? 'Driver';
    return _trackData?['driver']?.toString() ?? 'Driver';
  }

  String? _driverVehicle() {
    final live = _liveTracking?.driver;
    final map = _driverMap;
    final parts = [
      live?.vehicleColor ?? map?['vehicle_color']?.toString(),
      live?.vehicleType ?? map?['vehicle_type']?.toString(),
    ]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('#'));
    final text = parts.join(' ');
    return text.isEmpty ? null : text;
  }

  double? _driverRating() {
    final live = _liveTracking?.driver?.rating;
    if (live != null) return live;
    return double.tryParse(_driverMap?['rating']?.toString() ?? '');
  }

  int? _etaMinutes() {
    final live = _liveTracking?.estimatedArrivalMinutes;
    if (live != null && live > 0) return live;
    final raw = int.tryParse(
      _trackData?['estimated_arrival_minutes']?.toString() ?? '',
    );
    return (raw != null && raw > 0) ? raw : null;
  }

  List<Map<String, dynamic>>? _timeline() {
    final raw = _trackData?['timeline'];
    if (raw == null) return null;
    return List<Map<String, dynamic>>.from(
      (raw as List).map(
        (e) => e is Map<String, dynamic> ? e : <String, dynamic>{},
      ),
    );
  }
}

/// Floating round control over the map (shadow outside the Material).
class _MapCircleButton extends StatelessWidget {
  const _MapCircleButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: CircleBorder(
          side: dark
              ? BorderSide(color: HomeColors.borderOf(context))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: 52, height: 52, child: Center(child: child)),
      ),
    );
  }
}

class _EtaPill extends StatelessWidget {
  const _EtaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = HomeColors.violetOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: HomeColors.violetTintOf(context),
        borderRadius: BorderRadius.circular(AppColors.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 15, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared card shell: surface + soft shadow (light) / hairline border (dark).
class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(22);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: dark ? BorderSide(color: borderColor) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: HomeColors.violetOf(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17,
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

class _ReviewOrderCard extends StatelessWidget {
  final String courierNumber;
  final String from;
  final String to;
  final String createdDate;
  final Color borderColor;

  const _ReviewOrderCard({
    required this.courierNumber,
    required this.from,
    required this.to,
    required this.createdDate,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    final orangeFill = dark ? AppColors.orangeTintDark : AppColors.orangeTint;
    return _SheetCard(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.receipt_long_rounded,
            text: 'Review Order',
          ),
          const SizedBox(height: 14),
          _DetailItem(
            icon: Icons.trip_origin_rounded,
            iconColor: AppColors.brandOrange,
            tileColor: orangeFill,
            label: l10n.from,
            value: from,
          ),
          const SizedBox(height: 12),
          _DetailItem(
            icon: Icons.location_on_rounded,
            iconColor: HomeColors.violetOf(context),
            tileColor: HomeColors.violetTintOf(context),
            label: l10n.to,
            value: to,
          ),
          const SizedBox(height: 12),
          _DetailItem(
            icon: Icons.tag_rounded,
            iconColor: HomeColors.textMutedOf(context),
            tileColor: HomeColors.surfaceElevatedOf(context),
            label: l10n.courierNumber,
            value: courierNumber,
          ),
          const SizedBox(height: 12),
          _DetailItem(
            icon: Icons.event_rounded,
            iconColor: HomeColors.textMutedOf(context),
            tileColor: HomeColors.surfaceElevatedOf(context),
            label: l10n.created,
            value: createdDate,
          ),
        ],
      ),
    );
  }
}

class _TrackingOrderCard extends StatelessWidget {
  final List<Map<String, dynamic>>? timeline;
  final Color borderColor;

  const _TrackingOrderCard({this.timeline, required this.borderColor});

  String _formatTimestamp(dynamic value) {
    if (value == null) return '—';
    final str = value.toString();
    try {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        return '${months[dt.month - 1]} ${dt.day}, ${dt.year} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final items = timeline ?? [];
    return _SheetCard(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.timeline_rounded,
            text: 'Tracking Order',
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Center(
              child: Column(
                children: [
                  Lottie.asset('assets/animations/browse.json', width: 120),
                  const SizedBox(height: 8),
                  Text(
                    'No tracking updates yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: HomeColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return _TrackingItem(
                title: item['event']?.toString() ?? '—',
                date: _formatTimestamp(item['timestamp']),
                isActive: item['status'] == 'current',
                isCompleted: item['status'] == 'completed',
                isLast: i == items.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _TrackingItem extends StatelessWidget {
  final String title;
  final String date;
  final bool isActive;
  final bool isCompleted;
  final bool isLast;

  const _TrackingItem({
    required this.title,
    required this.date,
    this.isActive = false,
    this.isCompleted = true,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final indigo = HomeColors.violetOf(context);
    final border = HomeColors.borderOf(context);
    final Color nodeColor;
    final Color nodeFill;
    final IconData? nodeIcon;
    if (isCompleted) {
      nodeColor = indigo;
      nodeFill = indigo;
      nodeIcon = Icons.check_rounded;
    } else if (isActive) {
      nodeColor = AppColors.brandOrange;
      nodeFill = HomeColors.isDark(context)
          ? AppColors.orangeTintDark
          : AppColors.orangeTint;
      nodeIcon = null;
    } else {
      nodeColor = border;
      nodeFill = HomeColors.surfaceOf(context);
      nodeIcon = null;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: nodeFill,
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: 2),
                  ),
                  child: nodeIcon != null
                      ? Icon(nodeIcon, size: 15, color: Colors.white)
                      : isActive
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.brandOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? indigo.withValues(alpha: 0.35)
                            : border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1, bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                      color: isActive || isCompleted
                          ? HomeColors.textPrimaryOf(context)
                          : HomeColors.textMutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: HomeColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color tileColor;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.iconColor,
    required this.tileColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.textMutedOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
