import 'dart:async';

import 'package:flutter/material.dart';
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
        (key.contains('ed') || key.contains('complete') || key.contains('done'))) {
      return l10n.trackingStatusDone;
    }
    if (key.contains('complete') || key.contains('done') || key.contains('finish')) {
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
      data['current_longitude'] ?? data['driver_longitude'] ?? data['longitude'],
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
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      final fallback = label == 'dropoff'
          ? widget.deliveryPosition
          : widget.pickupPosition;
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
        (widget.pickupPosition!.latitude + widget.deliveryPosition!.latitude) / 2,
        (widget.pickupPosition!.longitude + widget.deliveryPosition!.longitude) / 2,
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
            gmaps.BitmapDescriptor.hueOrange,
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
            gmaps.BitmapDescriptor.hueGreen,
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
          points: _routePolylinePoints != null && _routePolylinePoints!.length >= 2
              ? _routePolylinePoints!.map(_toG).toList()
              : [_toG(routeStart), _toG(routeEnd)],
          color: HomeColors.violet,
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
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final borderColor = HomeColors.borderOf(context);
          return Scaffold(
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
                // Back + call support
                Positioned(
                  top: 40,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: HomeColors.surfaceElevatedOf(context),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: HomeColors.textPrimaryOf(context)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: HomeColors.surfaceElevatedOf(context),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const CallSupportButton(compact: true),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Positioned(
                  top: 40,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: HomeColors.surfaceElevatedOf(context),
                      borderRadius: BorderRadius.circular(AppColors.radiusFull),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: StatusChip(status: statusText),
                  ),
                ),
                if (!_isLoadingTrack &&
                    _trackError == null &&
                    !_trackingAvailable)
                  Positioned(
                    top: 96,
                    left: 16,
                    right: 16,
                    child: Material(
                      color: HomeColors.surfaceElevatedOf(context).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          _liveTracking?.message ??
                              context.l10n.courierFindingNearestDrivers,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: HomeColors.textPrimaryOf(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                      decoration: BoxDecoration(
                        color: HomeColors.surfaceOf(context),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppColors.radiusLG),
                          topRight: Radius.circular(AppColors.radiusLG),
                        ),
                        border: Border(
                          top: BorderSide(color: borderColor),
                          left: BorderSide(color: borderColor),
                          right: BorderSide(color: borderColor),
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
                              color: HomeColors.borderOf(context),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Current Status Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppColors.spaceMD),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  HomeColors.violet,
                                  Color(0xFF6F56E8),
                                ],
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppColors.radiusLG),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(statusIcon,
                                      color: Colors.white, size: 32),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friendlyStatus,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (_trackData?['pickup_location']
                                                        ?.toString() ??
                                                    widget.pickupLocation)
                                                .length >
                                            40
                                            ? '${(_trackData?['pickup_location']?.toString() ?? widget.pickupLocation).substring(0, 40)}...'
                                            : (_trackData?['pickup_location']
                                                    ?.toString() ??
                                                widget.pickupLocation),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: context.l10n.easySpeakHint,
                                  icon: const Icon(Icons.volume_up_rounded,
                                      color: Colors.white),
                                  onPressed: () {
                                    VoiceHintService.instance
                                        .speak(friendlyStatus);
                                  },
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
                                          child: Text(
                                            _trackError!,
                                            style: TextStyle(
                                              color: HomeColors.textMutedOf(context),
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    : SingleChildScrollView(
                                        controller: scrollController,
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          children: [
                                            // Driver Information (only when driver assigned)
                                            if (_trackingAvailable &&
                                                (_liveTracking?.driver !=
                                                        null ||
                                                    _trackData?['driver'] !=
                                                        null)) ...[
                                              DriverContactCard(
                                                driverName: _liveTracking
                                                        ?.driver?.name ??
                                                    (_trackData!['driver']
                                                            is Map<String,
                                                                dynamic>
                                                        ? ((_trackData![
                                                                        'driver']
                                                                    as Map<
                                                                        String,
                                                                        dynamic>)[
                                                                'name']
                                                            ?.toString() ??
                                                            'Driver')
                                                        : _trackData!['driver']
                                                            .toString()),
                                                details: [
                                                  _liveTracking?.driver
                                                      ?.vehiclePlateNumber,
                                                  _driverPhone(),
                                                ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                                                borderColor: borderColor,
                                                onCall: _driverPhone() != null
                                                    ? _callDriver
                                                    : null,
                                                onMessage: _messageDriver,
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            // Review Order
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
                                              createdDate: _trackData?['created_at']
                                                      ?.toString() ??
                                                  '—',
                                              borderColor: borderColor,
                                            ),
                                            const SizedBox(height: 16),
                                            // Tracking Order (timeline from API)
                                            _TrackingOrderCard(
                                              timeline: _trackData?[
                                                          'timeline'] !=
                                                      null
                                                  ? List<
                                                      Map<String,
                                                          dynamic>>.from(
                                                      (_trackData![
                                                                  'timeline']
                                                              as List)
                                                          .map((e) => e is Map<
                                                                  String,
                                                                  dynamic>
                                                              ? e
                                                              : <String,
                                                                  dynamic>{}))
                                                  : null,
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
          );
        },
      ),
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
    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: HomeColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          _DetailItem(label: 'Courier Number', value: courierNumber),
          const SizedBox(height: 12),
          _DetailItem(
            label: 'From',
            value: from.length > 30 ? '${from.substring(0, 30)}...' : from,
          ),
          const SizedBox(height: 12),
          _DetailItem(
            label: 'To',
            value: to.length > 30 ? '${to.substring(0, 30)}...' : to,
          ),
          const SizedBox(height: 12),
          _DetailItem(label: 'Created', value: createdDate),
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
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
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
    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: HomeColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracking Order',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textPrimaryOf(context),
                ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Column(
              children: [
                Lottie.asset('assets/animations/browse.json', width: 120),
                const SizedBox(height: 8),
                Text(
                  'No tracking updates yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HomeColors.textMutedOf(context),
                      ),
                ),
              ],
            )
          else
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isCurrent = item['status'] == 'current';
              final isCompleted = item['status'] == 'completed';
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < items.length - 1 ? 16 : 0,
                ),
                child: _TrackingItem(
                  title: item['event']?.toString() ?? '—',
                  date: _formatTimestamp(item['timestamp']),
                  isActive: isCurrent,
                  isCompleted: isCompleted,
                ),
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

  const _TrackingItem({
    required this.title,
    required this.date,
    this.isActive = false,
    this.isCompleted = true,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor = HomeColors.textMutedOf(context);
    if (isActive) dotColor = HomeColors.violet;
    if (isCompleted) dotColor = AppColors.delivered;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: HomeColors.textPrimaryOf(context),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HomeColors.textMutedOf(context),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HomeColors.textMutedOf(context),
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: HomeColors.textPrimaryOf(context),
                ),
          ),
        ),
      ],
    );
  }
}


