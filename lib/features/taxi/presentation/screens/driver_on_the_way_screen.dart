import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/app/services/google_directions_service.dart';
import 'package:hudhud_delivery/app/config/google_maps_api_key_provider.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_navigation.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/presentation/screen/payment_initiate_result_screen.dart';
import 'package:hudhud_delivery/features/taxi/data/models/ride_request_result.dart';
import 'package:hudhud_delivery/features/taxi/data/ride_data_provider.dart';
import 'package:hudhud_delivery/features/taxi/utils/ride_payment_helper.dart';
import 'package:shimmer/shimmer.dart';

class DriverOnTheWayScreen extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupAddress;
  final String destinationAddress;
  final String tripType;
  final int price;
  final String paymentMethod;
  final int? rideId;
  final String driverName;
  final String? driverPhone;
  final LatLng? driverPosition;
  final String currency;
  final Map<String, dynamic>? paymentDetails;

  const DriverOnTheWayScreen({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.tripType,
    required this.price,
    required this.paymentMethod,
    this.rideId,
    this.driverName = 'Driver',
    this.driverPhone,
    this.driverPosition,
    this.currency = 'KES',
    this.paymentDetails,
  });

  @override
  State<DriverOnTheWayScreen> createState() => _DriverOnTheWayScreenState();
}

class _DriverOnTheWayScreenState extends State<DriverOnTheWayScreen> {
  final RideDataProvider _rideDataProvider = RideDataProvider();
  late final PaymentRepository _paymentRepository;
  gmaps.GoogleMapController? _mapController;
  LatLng? _driverPosition;
  String _driverName = 'Driver';
  String? _driverPhone;
  Timer? _pollTimer;
  List<LatLng>? _routePolylinePoints;
  double? _routeDistanceKm;
  bool _isLoadingRoute = true;
  bool? _hasGoogleMapsApiKey;
  bool _paymentInitiated = false;
  bool _isInitiatingPayment = false;

  static gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  @override
  void initState() {
    super.initState();
    _paymentRepository = PaymentRepository(
      paymentDataProvider: PaymentDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _driverName = widget.driverName;
    _driverPhone = widget.driverPhone;
    _driverPosition = widget.driverPosition;
    _loadMapsAvailability();
    _fetchRouteDirections();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshActiveRide(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshActiveRide();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  LatLng? _parseDriverLocation(Map<String, dynamic> ride) {
    LatLng? fromCoords(dynamic lat, dynamic lng) {
      final latitude = double.tryParse(lat?.toString() ?? '');
      final longitude = double.tryParse(lng?.toString() ?? '');
      if (latitude == null || longitude == null) return null;
      return LatLng(latitude, longitude);
    }

    final direct = fromCoords(
      ride['current_latitude'] ?? ride['driver_latitude'],
      ride['current_longitude'] ?? ride['driver_longitude'],
    );
    if (direct != null) return direct;

    final driverLocation = ride['driver_location'];
    if (driverLocation is Map) {
      final nested = fromCoords(
        driverLocation['latitude'] ?? driverLocation['lat'],
        driverLocation['longitude'] ?? driverLocation['lng'],
      );
      if (nested != null) return nested;
    }

    final driver = ride['driver'];
    if (driver is Map) {
      return fromCoords(
        driver['latitude'] ?? driver['lat'] ?? driver['current_latitude'],
        driver['longitude'] ?? driver['lng'] ?? driver['current_longitude'],
      );
    }
    return null;
  }

  Future<void> _refreshActiveRide() async {
    final result = await _rideDataProvider.getActiveRide();
    if (!mounted) return;

    final ride = _unwrapRidePayload(result['data']);
    if (ride == null) return;

    final status = (ride['status']?.toString() ?? '').toLowerCase();
    if (status == 'completed') {
      await _onRideCompleted(ride);
      return;
    }

    final nested = ride['driver'];
    final name = nested is Map
        ? nested['name']?.toString()
        : ride['driver_name']?.toString();
    final phone = nested is Map
        ? nested['phone']?.toString()
        : ride['driver_phone']?.toString();

    setState(() {
      if (name != null && name.isNotEmpty) _driverName = name;
      if (phone != null && phone.isNotEmpty) _driverPhone = phone;
      final loc = _parseDriverLocation(ride);
      if (loc != null) _driverPosition = loc;
    });
  }

  Map<String, dynamic>? _unwrapRidePayload(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final nestedData = map['data'];
    if (nestedData is Map) {
      final inner = Map<String, dynamic>.from(nestedData);
      if (inner['ride'] is Map) {
        return Map<String, dynamic>.from(inner['ride'] as Map);
      }
      if (inner['id'] != null || inner['status'] != null) return inner;
    }
    if (map['ride'] is Map) {
      return Map<String, dynamic>.from(map['ride'] as Map);
    }
    if (map['id'] != null || map['status'] != null) return map;
    return null;
  }

  Future<void> _onRideCompleted(Map<String, dynamic> ride) async {
    if (_paymentInitiated || _isInitiatingPayment) return;
    final rideId = widget.rideId ??
        int.tryParse(ride['id']?.toString() ?? '') ??
        int.tryParse(ride['ride_id']?.toString() ?? '');
    if (rideId == null || rideId <= 0) return;

    setState(() {
      _paymentInitiated = true;
      _isInitiatingPayment = true;
    });
    _pollTimer?.cancel();

    final amount =
        parseRideFare(ride) ?? widget.price.toDouble();
    final currency = parseRideCurrency(ride, fallback: widget.currency);
    final method =
        ride['payment_method']?.toString() ?? widget.paymentMethod;

    try {
      final result = await initiateRidePayment(
        repo: _paymentRepository,
        rideId: rideId,
        paymentMethodCode: method,
        amount: amount > 0 ? amount : widget.price.toDouble(),
        currency: currency,
        paymentDetails: widget.paymentDetails,
      );
      if (!mounted) return;
      setState(() => _isInitiatingPayment = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentInitiateResultScreen(
            result: result,
            orderId: rideId.toString(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitiatingPayment = false;
        _paymentInitiated = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFacingApiError(e)),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _callDriver() async {
    final phone = _driverPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _messageDriver() async {
    final rideId = widget.rideId;
    if (rideId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open chat. Missing ride ID.')),
      );
      return;
    }
    await openRideChat(context, rideId);
  }

  Future<void> _loadMapsAvailability() async {
    final key = await GoogleMapsApiKeyProvider.getKey();
    if (!mounted) return;
    setState(() {
      _hasGoogleMapsApiKey = key.trim().isNotEmpty;
    });
  }

  Future<void> _fetchRouteDirections() async {
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

  Color _cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : AppColors.lightBorder;
  }

  Widget _buildMapBackButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: _cardBorder(context)),
      ),
      child: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final borderColor = _cardBorder(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMapOrFallback(context),
          ),
          Positioned(
            top: 48,
            left: AppColors.spaceMD,
            child: _buildMapBackButton(context),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.48,
            minChildSize: 0.32,
            maxChildSize: 0.82,
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
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppColors.spaceMD),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.taxiStatusDriverOnTheWay,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const StatusChip(status: 'on_the_way'),
                              ],
                            ),
                            const SizedBox(height: AppColors.spaceMD),
                            Container(
                              padding: const EdgeInsets.all(AppColors.spaceMD),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppColors.radiusMD,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 32,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: AppColors.spaceMD),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your Driver',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _driverName,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.tripType,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _ContactButton(
                                    icon: Icons.message_rounded,
                                    borderColor: borderColor,
                                    onPressed: widget.rideId != null
                                        ? _messageDriver
                                        : null,
                                  ),
                                  if (_driverPhone != null &&
                                      _driverPhone!.isNotEmpty) ...[
                                    const SizedBox(width: AppColors.spaceSM),
                                    _ContactButton(
                                      icon: Icons.phone_rounded,
                                      borderColor: borderColor,
                                      onPressed: _callDriver,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppColors.spaceMD),
                            Container(
                              padding: const EdgeInsets.all(AppColors.spaceMD),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                children: [
                                  _LocationRow(
                                    icon: Icons.trip_origin_rounded,
                                    iconColor: AppColors.successColor,
                                    label: l10n.taxiPickup,
                                    address: widget.pickupAddress,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 11),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        height: 20,
                                        child: CustomPaint(
                                          painter: _DottedLinePainter(
                                            color: colorScheme.outlineVariant,
                                          ),
                                          size: const Size(2, 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _LocationRow(
                                    icon: Icons.location_on_rounded,
                                    iconColor: AppColors.errorColor,
                                    label: l10n.taxiDestination,
                                    address: widget.destinationAddress,
                                  ),
                                  if (_routeDistanceKm != null ||
                                      _isLoadingRoute) ...[
                                    const SizedBox(height: AppColors.spaceMD),
                                    Divider(color: borderColor, height: 1),
                                    const SizedBox(height: AppColors.spaceMD),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.straighten_rounded,
                                          size: 18,
                                          color: AppColors.primaryColor,
                                        ),
                                        const SizedBox(width: AppColors.spaceSM),
                                        if (_isLoadingRoute)
                                          _RouteShimmer()
                                        else if (_routeDistanceKm != null)
                                          Text(
                                            l10n.taxiDistanceKm(
                                              _routeDistanceKm!
                                                  .toStringAsFixed(2),
                                            ),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppColors.spaceMD),
                            Container(
                              padding: const EdgeInsets.all(AppColors.spaceMD),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.labelPaymentMethod,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.paymentMethod.toUpperCase(),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    l10n.taxiFareAmount('${widget.price}'),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppColors.spaceMD),
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

  Widget _buildMapOrFallback(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (_hasGoogleMapsApiKey == null) {
      return _MapLoadingShimmer();
    }
    if (_hasGoogleMapsApiKey == false) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppColors.spaceLG),
          child: Text(
            l10n.taxiGoogleMapsNotConfigured,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
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
            gmaps.BitmapDescriptor.hueGreen,
          ),
        ),
        if (_driverPosition != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('driver'),
            position: _toG(_driverPosition!),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueYellow,
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

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final Color borderColor;
  final VoidCallback? onPressed;

  const _ContactButton({
    required this.icon,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: enabled ? 0.35 : 0.15),
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: AppColors.primaryColor.withValues(alpha: enabled ? 1 : 0.4),
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: AppColors.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 0.0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RouteShimmer extends StatelessWidget {
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
        width: 80,
        height: 14,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _MapLoadingShimmer extends StatelessWidget {
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
