import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
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

  Widget _hero(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final Color fg = _isTerminal
        ? HomeColors.textMutedOf(context)
        : HomeColors.violetOf(context);
    final Color bg = _isTerminal
        ? HomeColors.surfaceElevatedOf(context)
        : HomeColors.violetTintOf(context);
    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: Container(
          margin: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark
                ? fg.withValues(alpha: 0.18)
                : HomeColors.surfaceOf(context),
          ),
          child: Icon(
            _isTerminal ? Icons.lock_rounded : Icons.password_rounded,
            size: 44,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _otpBoxes(BuildContext context, String otp) {
    final dark = HomeColors.isDark(context);
    final accent = HomeColors.violetOf(context);
    final chars = otp.split('');
    return Semantics(
      label: chars.join(' '),
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < chars.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Container(
                  width: 54,
                  height: 66,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dark
                        ? HomeColors.surfaceElevatedOf(context)
                        : HomeColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent, width: 2),
                    boxShadow: AppColors.softShadow(context),
                  ),
                  child: Text(
                    chars[i],
                    style: TextStyle(
                      color: HomeColors.textPrimaryOf(context),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otp = widget.otp?.trim();
    final tracking = _trackingNumber;
    final showOtp = !_isTerminal && otp != null && otp.isNotEmpty;
    final dark = HomeColors.isDark(context);

    return CourierTheme.wrap(
      context,
      child: Scaffold(
        backgroundColor: HomeColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: HomeColors.backgroundOf(context),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 26),
            color: HomeColors.textPrimaryOf(context),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Delivery verification',
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hero(context),
                      const SizedBox(height: 20),
                      Text(
                        _isTerminal
                            ? 'Verification closed'
                            : 'Share this code with your driver',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: HomeColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tracking != null && tracking.isNotEmpty
                            ? 'Tracking: $tracking'
                            : 'Delivery #${widget.deliveryId}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: HomeColors.textMutedOf(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_isLoadingStatus && !_isTerminal)
                        const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: HomeColors.orange,
                            ),
                          ),
                        )
                      else if (_isTerminal)
                        Text(
                          'This delivery is closed. The verification code is '
                          'no longer valid.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: HomeColors.textSecondaryOf(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        )
                      else if (showOtp)
                        _otpBoxes(context, otp)
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sms_rounded,
                              size: 26,
                              color: HomeColors.violetOf(context),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Check your SMS for the verification code.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: HomeColors.textSecondaryOf(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (!_isTerminal && !_isLoadingStatus) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                            decoration: BoxDecoration(
                              color: AppColors.successColor.withValues(
                                alpha: dark ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppColors.radiusFull,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.expiresOnDeliveryVerification
                                      ? Icons.verified_rounded
                                      : Icons.timer_rounded,
                                  color: AppColors.successColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    widget.expiresOnDeliveryVerification
                                        ? 'Valid until delivery verification'
                                        : 'Valid for this delivery',
                                    style: TextStyle(
                                      color: HomeColors.textPrimaryOf(context),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (!_isTerminal) ...[
                        const SizedBox(height: 28),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppColors.softShadow(context),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: HomeColors.surfaceOf(context),
                              borderRadius: BorderRadius.circular(20),
                              border: dark
                                  ? Border.all(
                                      color: HomeColors.borderOf(context),
                                    )
                                  : null,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.warningColor.withValues(
                                      alpha: dark ? 0.2 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    size: 26,
                                    color: AppColors.warningColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Do not share this code with anyone except '
                                    'your HudHud driver at drop-off. HudHud '
                                    'will never ask for it by phone.',
                                    style: TextStyle(
                                      color: HomeColors.textSecondaryOf(
                                        context,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: _PrimaryButton(
                  label: context.l10n.actionDone,
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The screen's single orange call to action (56px, radius 18).
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: HomeColors.isDark(context)
            ? const []
            : [
                BoxShadow(
                  color: AppColors.brandOrange.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: HomeColors.orange,
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
