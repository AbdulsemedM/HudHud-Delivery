import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_notification.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

/// Displays the delivery OTP for the customer to share with the driver.
///
/// Never logs [otp] to analytics, crash reports, or debug output.
class VerifyDeliveryOtpScreen extends StatefulWidget {
  final int deliveryId;
  final String? otp;
  final bool expiresOnDeliveryVerification;
  final String? trackingNumber;

  const VerifyDeliveryOtpScreen({
    super.key,
    required this.deliveryId,
    this.otp,
    this.expiresOnDeliveryVerification = true,
    this.trackingNumber,
  });

  @override
  State<VerifyDeliveryOtpScreen> createState() =>
      _VerifyDeliveryOtpScreenState();
}

class _VerifyDeliveryOtpScreenState extends State<VerifyDeliveryOtpScreen> {
  Timer? _statusPollTimer;
  String? _trackingNumber;
  String? _deliveryStatus;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _trackingNumber = widget.trackingNumber;
    _refreshDeliveryState();
    _statusPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshDeliveryState(silent: true),
    );
  }

  Future<void> _refreshDeliveryState({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoadingStatus = true);
    }

    final repository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    final result = await repository.getUserDeliveryDetails(widget.deliveryId);
    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final status = resolveDeliveryStatus(data);
      setState(() {
        _deliveryStatus = status;
        _trackingNumber ??= data?['tracking_number']?.toString();
        _isLoadingStatus = false;
      });

      if (isDeliveryTerminalStatus(status)) {
        _statusPollTimer?.cancel();
      }
    } else if (!silent) {
      setState(() => _isLoadingStatus = false);
    } else if (_isLoadingStatus) {
      setState(() => _isLoadingStatus = false);
    }
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  bool get _isTerminal => isDeliveryTerminalStatus(_deliveryStatus);

  @override
  Widget build(BuildContext context) {
    final otp = widget.otp?.trim();
    final tracking = _trackingNumber;
    final showOtp = !_isTerminal && otp != null && otp.isNotEmpty;

    return CourierTheme.wrap(
      context,
      child: Scaffold(
        backgroundColor: HomeColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: HomeColors.surfaceOf(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: HomeColors.textPrimaryOf(context),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Delivery verification',
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.spaceMD),
                decoration: BoxDecoration(
                  color: HomeColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(AppColors.radiusLG),
                  border: Border.all(color: HomeColors.borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTerminal
                          ? 'Verification closed'
                          : 'Share this code with your driver',
                      style: TextStyle(
                        color: HomeColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tracking != null && tracking.isNotEmpty
                          ? 'Tracking: $tracking'
                          : 'Delivery #${widget.deliveryId}',
                      style: TextStyle(
                        color: HomeColors.textSecondaryOf(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoadingStatus && !_isTerminal)
                      const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_isTerminal)
                      Text(
                        'This delivery is closed. The verification code is '
                        'no longer valid.',
                        style: TextStyle(
                          color: HomeColors.textSecondaryOf(context),
                          fontSize: 15,
                          height: 1.45,
                        ),
                      )
                    else if (showOtp)
                      Center(
                        child: Text(
                          otp,
                          style: const TextStyle(
                            color: HomeColors.violet,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 12,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          'Check your SMS for the verification code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: HomeColors.textSecondaryOf(context),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    if (!_isTerminal && !_isLoadingStatus) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.expiresOnDeliveryVerification
                                ? Icons.verified_outlined
                                : Icons.timer_outlined,
                            color: HomeColors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.expiresOnDeliveryVerification
                                ? 'Valid until delivery verification'
                                : 'Valid for this delivery',
                            style: TextStyle(
                              color: HomeColors.textPrimaryOf(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              if (!_isTerminal)
                Container(
                  padding: const EdgeInsets.all(AppColors.spaceMD),
                  decoration: BoxDecoration(
                    color: HomeColors.surfaceElevatedOf(context),
                    borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    border: Border.all(color: HomeColors.borderOf(context)),
                  ),
                  child: Text(
                    'Do not share this code with anyone except your HudHud '
                    'driver at drop-off. HudHud will never ask for it by phone.',
                    style: TextStyle(
                      color: HomeColors.textSecondaryOf(context),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                height: AppColors.buttonHeightMD,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: HomeColors.violet,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
