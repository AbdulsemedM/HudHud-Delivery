import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/app/navigation/dashboard_navigation.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_home_refresh.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_cancel.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:lottie/lottie.dart';
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
  });

  @override
  State<FindingCourierScreen> createState() => _FindingCourierScreenState();
}

class _FindingCourierScreenState extends State<FindingCourierScreen> {
  late final CourierRepository _courierRepository;
  Timer? _pollTimer;
  bool _isCancelling = false;
  bool _hasNavigated = false;

  static const _searchingStatuses = {
    'searching',
    'pending',
    'requested',
    'looking_for_driver',
    'looking_for_courier',
    'created',
    'request_received',
    'request received',
  };

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _pollAssignment();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollAssignment(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool _isAssigned(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data['driver'] != null || data['driver_id'] != null) return true;
    final status =
        (resolveDeliveryStatus(data) ?? '').toLowerCase().replaceAll(' ', '_');
    if (status.isEmpty) return false;
    if (_searchingStatuses.contains(status) ||
        _searchingStatuses.contains(status.replaceAll('_', ' '))) {
      return false;
    }
    if (status.contains('cancel')) return false;
    return true;
  }

  Future<void> _pollAssignment() async {
    if (_hasNavigated || _isCancelling || !mounted) return;

    Map<String, dynamic>? data;

    if (widget.deliveryId != null) {
      final track = await _courierRepository.getDeliveryTrack(widget.deliveryId!);
      if (track['success'] == true) {
        data = track['data'] as Map<String, dynamic>?;
      }
    }

    if (!_isAssigned(data)) {
      final active = await _courierRepository.getUserActiveDelivery();
      if (active['success'] == true) {
        data = active['delivery'] as Map<String, dynamic>?;
      }
    }

    if (!mounted || _hasNavigated) return;
    if (!_isAssigned(data)) return;

    final deliveryId = widget.deliveryId ??
        (data?['id'] is int
            ? data!['id'] as int
            : int.tryParse(data?['id']?.toString() ?? ''));

    _hasNavigated = true;
    _pollTimer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryTrackingScreen(
          deliveryId: deliveryId,
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
      Navigator.pop(context);
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
    Navigator.pop(context);
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
          const borderColor = HomeColors.border;

          return Scaffold(
            backgroundColor: HomeColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppColors.spaceMD),
                    padding: const EdgeInsets.all(AppColors.spaceLG),
                    decoration: BoxDecoration(
                      color: HomeColors.surface,
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Lottie.asset(
                            'assets/animations/loading.json',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      HomeColors.violet,
                                    ),
                                    strokeWidth: 3,
                                  ),
                                  const SizedBox(height: AppColors.spaceMD),
                                  Text(
                                    'Looking for courier...',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: HomeColors.textPrimary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppColors.spaceMD),
                        Text(
                          'Finding a Courier',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: HomeColors.violet,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We are searching for the best courier near you',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: HomeColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppColors.spaceLG),
                        _LoadingDots(),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppColors.spaceMD,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: AppColors.buttonHeightMD,
                      child: FilledButton(
                        onPressed: _goToHome,
                        style: FilledButton.styleFrom(
                          backgroundColor: HomeColors.violet,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusLG),
                          ),
                        ),
                        child: const Text(
                          'Go to home',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.all(AppColors.spaceMD),
                    child: SizedBox(
                      width: double.infinity,
                      height: AppColors.buttonHeightMD,
                      child: OutlinedButton(
                        onPressed: _isCancelling ? null : _cancelOrder,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.errorColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusLG),
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
