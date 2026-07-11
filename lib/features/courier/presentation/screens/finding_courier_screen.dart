import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:lottie/lottie.dart';
import 'delivery_tracking_screen.dart';

class FindingCourierScreen extends StatefulWidget {
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
  final bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateCourierSearch();
  }

  Future<void> _simulateCourierSearch() async {
    // Simulate searching for a courier
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted && _isLoading) {
      // Navigate to tracking screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryTrackingScreen(
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
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
              padding: const EdgeInsets.all(AppColors.spaceLG),
              decoration: BoxDecoration(
                color: scheme.surface,
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
                                AppColors.primaryColor,
                              ),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: AppColors.spaceMD),
                            Text(
                              'Looking for courier...',
                              style: theme.textTheme.bodyMedium,
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
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We are searching for the best courier near you',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppColors.spaceLG),
                  _LoadingDots(),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppColors.spaceMD),
              child: SizedBox(
                width: double.infinity,
                height: AppColors.buttonHeightMD,
                child: OutlinedButton(
                  onPressed: _cancelOrder,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                  child: const Text(
                    'Cancel Order',
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

