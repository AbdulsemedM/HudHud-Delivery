import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
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

  Map<String, dynamic>? _trackData;
  bool _isLoadingTrack = true;
  String? _trackError;
  List<LatLng>? _routePolylinePoints;

  late final CourierRepository _courierRepository;

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );

    if (widget.pickupPosition != null && widget.deliveryPosition != null) {
      _fetchRouteDirections();
    }

    if (widget.deliveryId != null) {
      _fetchTrackData();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 8),
        (_) => _fetchTrackData(),
      );
    } else {
      _isLoadingTrack = false;
    }
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

  Future<void> _fetchRouteDirections() async {
    if (widget.pickupPosition == null || widget.deliveryPosition == null) return;
    final result = await GoogleDirectionsService.getDirections(
      originLat: widget.pickupPosition!.latitude,
      originLng: widget.pickupPosition!.longitude,
      destLat: widget.deliveryPosition!.latitude,
      destLng: widget.deliveryPosition!.longitude,
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
    if (widget.deliveryId == null) return;
    try {
      final result =
          await _courierRepository.getDeliveryTrack(widget.deliveryId!);
      if (mounted) {
        setState(() {
          _isLoadingTrack = false;
          if (result['success'] == true) {
            _trackData = result['data'] as Map<String, dynamic>?;
            _vehiclePosition = _parseDriverLocation(_trackData);
            _trackError = null;
          } else {
            _trackData = null;
            _trackError = result['message'] as String?;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTrack = false;
          _trackData = null;
          _trackError = 'Failed to load tracking';
        });
      }
    }
  }

  String _formatTimestamp(dynamic value) {
    if (value == null) return '—';
    final str = value.toString();
    try {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        return '${dt.day} ${_monthName(dt.month)} ${dt.year}, '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return str;
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
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
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
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
    if (widget.pickupPosition != null && widget.deliveryPosition != null) {
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          points: _routePolylinePoints != null && _routePolylinePoints!.length >= 2
              ? _routePolylinePoints!.map(_toG).toList()
              : [_toG(widget.pickupPosition!), _toG(widget.deliveryPosition!)],
          color: HomeColors.violet,
          width: 4,
        ),
      );
    }

    final statusText = _trackData?['current_status']?.toString() ??
        _trackData?['status']?.toString() ??
        'in_progress';
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          const borderColor = HomeColors.border;
          return Scaffold(
            backgroundColor: HomeColors.background,
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
                // Back button
                Positioned(
                  top: 40,
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
                      onPressed: () => Navigator.pop(context),
                    ),
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
                      color: HomeColors.surfaceElevated,
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
                // Bottom Sheet Modal
                DraggableScrollableSheet(
                  initialChildSize: 0.5,
                  minChildSize: 0.35,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: HomeColors.surface,
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
                              color: HomeColors.border,
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (_trackData?['pickup_location']
                                                        ?.toString() ??
                                                    widget.pickupLocation)
                                                .length >
                                            30
                                            ? '${(_trackData?['pickup_location']?.toString() ?? widget.pickupLocation).substring(0, 30)}...'
                                            : (_trackData?['pickup_location']
                                                    ?.toString() ??
                                                widget.pickupLocation),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _trackData?['current_status']
                                                ?.toString() ??
                                            _trackData?[
                                                    'estimated_delivery_time']
                                                ?.toString() ??
                                            'Delivery in progress',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.send,
                                        color: Colors.white),
                                    onPressed: () {
                                      // TODO: Implement send action
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
                                          child: Text(
                                            _trackError!,
                                            style: const TextStyle(
                                              color: HomeColors.textMuted,
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
                                            if (_trackData?['driver'] !=
                                                null) ...[
                                              _DriverCard(
                                                driverName: _trackData![
                                                            'driver']
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
                                                        .toString(),
                                                borderColor: borderColor,
                                                onCall: () {
                                                  // TODO: Implement call
                                                },
                                                onMessage: () {
                                                  // TODO: Implement message
                                                },
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
                                              createdDate: _formatTimestamp(
                                                  _trackData?[
                                                      'last_updated']),
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

class _DriverCard extends StatelessWidget {
  final String driverName;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final Color borderColor;

  const _DriverCard({
    required this.driverName,
    required this.onCall,
    required this.onMessage,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: HomeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Profile Picture
          const CircleAvatar(
            radius: 30,
            backgroundColor: HomeColors.surface,
            child: Icon(
              Icons.person,
              size: 30,
              color: HomeColors.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          // Driver Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Driver',
                  style: TextStyle(
                    fontSize: 14,
                    color: HomeColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: HomeColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  size: 20, color: HomeColors.textPrimary),
            ),
            onPressed: onMessage,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: HomeColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone,
                  size: 20, color: HomeColors.textPrimary),
            ),
            onPressed: onCall,
          ),
        ],
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
        color: HomeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: HomeColors.textPrimary,
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
        color: HomeColors.surfaceElevated,
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
                  color: HomeColors.textPrimary,
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
                        color: HomeColors.textMuted,
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
    Color dotColor = HomeColors.textMuted;
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
                      color: HomeColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HomeColors.textMuted,
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
                  color: HomeColors.textMuted,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: HomeColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}


