import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/snackbar_util.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/taxi/data/models/ride_request_result.dart';
import 'package:hudhud_delivery/features/taxi/data/ride_data_provider.dart';
import 'package:lottie/lottie.dart';
import 'driver_on_the_way_screen.dart';

class FindingDriverScreen extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupAddress;
  final String destinationAddress;
  final String tripType;
  final int price;
  final String paymentMethod;
  final int? rideId;
  final String currency;
  final Map<String, dynamic>? paymentDetails;

  const FindingDriverScreen({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.tripType,
    required this.price,
    required this.paymentMethod,
    this.rideId,
    this.currency = 'KES',
    this.paymentDetails,
  });

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen> {
  final RideDataProvider _rideDataProvider = RideDataProvider();
  Timer? _pollTimer;
  bool _isCancelling = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _pollActiveRide();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollActiveRide(),
    );
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

  String _driverName(Map<String, dynamic> ride) {
    final nested = ride['driver'];
    if (nested is Map) {
      final name = nested['name']?.toString();
      if (name != null && name.isNotEmpty) return name;
    }
    final flat = ride['driver_name']?.toString();
    if (flat != null && flat.isNotEmpty) return flat;
    return 'Driver';
  }

  String? _driverPhone(Map<String, dynamic> ride) {
    final nested = ride['driver'];
    if (nested is Map) {
      final phone = nested['phone']?.toString();
      if (phone != null && phone.isNotEmpty) return phone;
    }
    final flat = ride['driver_phone']?.toString();
    if (flat != null && flat.isNotEmpty) return flat;
    return null;
  }

  int? _rideIdFrom(Map<String, dynamic> ride) {
    final id = ride['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  Future<void> _pollActiveRide() async {
    if (_hasNavigated || _isCancelling || !mounted) return;

    final result = await _rideDataProvider.getActiveRide();
    if (!mounted || _hasNavigated || _isCancelling) return;

    if (result['statusCode'] != 200 || result['data'] == null) return;

    final ride = result['data'] as Map<String, dynamic>;
    final status = (ride['status'] as String? ?? 'searching').toLowerCase();
    final hasDriver = ride['driver_id'] != null || ride['driver'] != null;

    if (status == 'searching' || !hasDriver) return;

    _hasNavigated = true;
    _pollTimer?.cancel();

    final estimatedFare =
        (double.tryParse(ride['estimated_fare']?.toString() ?? '') ??
                widget.price.toDouble())
            .round();
    final paymentMethod =
        ride['payment_method'] as String? ?? widget.paymentMethod;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DriverOnTheWayScreen(
          pickupLocation: widget.pickupLocation,
          destinationLocation: widget.destinationLocation,
          pickupAddress: widget.pickupAddress,
          destinationAddress: widget.destinationAddress,
          tripType: widget.tripType,
          price: estimatedFare,
          paymentMethod: paymentMethod,
          rideId: widget.rideId ?? _rideIdFrom(ride),
          driverName: _driverName(ride),
          driverPhone: _driverPhone(ride),
          driverPosition: _parseDriverLocation(ride),
          currency: ride['currency']?.toString() ?? widget.currency,
          paymentDetails: widget.paymentDetails,
        ),
      ),
    );
  }

  Future<void> _cancelTrip() async {
    if (_isCancelling) return;

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
        ),
        title: const Text('Cancel Trip'),
        content: const Text('Are you sure you want to cancel this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: Text(l10n.actionYesCancel),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final rideId = widget.rideId;
    if (rideId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to cancel ride. Missing ride ID.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isCancelling = true);
    final result = await _rideDataProvider.cancelRide(rideId: rideId);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    final statusCode = result['statusCode'] as int?;
    final success = statusCode != null && statusCode >= 200 && statusCode < 300;
    if (success) {
      _pollTimer?.cancel();
      final refund = parseRideCancelRefundResponse(result['data']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatRideCancelRefundMessage(refund)),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.pop(context);
    } else if (isServiceComingSoonResult(result)) {
      SnackbarUtil.showComingSoon(
        context,
        result['errorMessage']?.toString() ?? 'Ride hailing is coming soon.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['errorMessage']?.toString() ?? 'Failed to cancel ride',
          ),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Color _cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final borderColor = _cardBorder(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          onPressed: _isCancelling ? null : _cancelTrip,
        ),
        title: Text(
          l10n.taxiStatusFindingDriver,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                width: 220,
                height: 220,
                child: Lottie.asset(
                  'assets/animations/browse.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: AppColors.spaceLG),
                        Text(
                          l10n.taxiStatusFindingDriver,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppColors.spaceLG),
              const StatusChip(status: 'searching'),
              const SizedBox(height: AppColors.spaceMD),
              Text(
                l10n.taxiStatusFindingDriver,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: AppColors.spaceSM),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppColors.spaceLG),
                child: Text(
                  'We are searching for the best driver near you',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppColors.spaceXL),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppColors.spaceMD),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppColors.radiusLG),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_taxi_rounded,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppColors.spaceSM),
                        Expanded(
                          child: Text(
                            widget.tripType,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          l10n.taxiFareAmount('${widget.price}'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppColors.spaceMD),
                    _LocationLine(
                      icon: Icons.trip_origin_rounded,
                      iconColor: AppColors.successColor,
                      address: widget.pickupAddress,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 11),
                      child: Container(
                        width: 2,
                        height: 16,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    _LocationLine(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.errorColor,
                      address: widget.destinationAddress,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _LoadingDots(),
              const SizedBox(height: AppColors.spaceLG),
              SizedBox(
                width: double.infinity,
                height: AppColors.buttonHeightMD,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _cancelTrip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorColor,
                    side: BorderSide(
                      color: AppColors.errorColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
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
                      : Text(
                          l10n.actionCancel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String address;

  const _LocationLine({
    required this.icon,
    required this.iconColor,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: AppColors.spaceMD),
        Expanded(
          child: Text(
            address,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LoadingDots extends StatefulWidget {
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
                color: AppColors.primaryColor.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
