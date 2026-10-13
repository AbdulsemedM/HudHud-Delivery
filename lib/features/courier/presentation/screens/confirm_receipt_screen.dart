import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/rate_delivery_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

class ConfirmReceiptScreen extends StatefulWidget {
  final int deliveryId;

  const ConfirmReceiptScreen({super.key, required this.deliveryId});

  @override
  State<ConfirmReceiptScreen> createState() => _ConfirmReceiptScreenState();
}

class _ConfirmReceiptScreenState extends State<ConfirmReceiptScreen> {
  late final CourierRepository _repository;
  Map<String, dynamic>? _delivery;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _loadDelivery();
  }

  Future<void> _loadDelivery() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _repository.getUserDeliveryDetails(widget.deliveryId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _delivery = result['data'] as Map<String, dynamic>?;
      } else {
        _error = result['message']?.toString() ?? 'Failed to load delivery';
      }
    });
  }

  Future<void> _confirmReceipt() async {
    setState(() => _isSubmitting = true);
    final result = await _repository.confirmDeliveryReceipt(widget.deliveryId);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Receipt confirmed. Thank you!',
          ),
          backgroundColor: AppColors.successColor,
        ),
      );
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RateDeliveryScreen(deliveryId: widget.deliveryId),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Could not confirm receipt',
        ),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorColor.withValues(
                  alpha: HomeColors.isDark(context) ? 0.2 : 0.1,
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 46,
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadDelivery,
              icon: const Icon(Icons.refresh_rounded, size: 24),
              label: Text(context.l10n.actionRetry),
              style: TextButton.styleFrom(
                foregroundColor: HomeColors.violetOf(context),
                minimumSize: const Size(48, 48),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    final delivery = _delivery;
    final dark = HomeColors.isDark(context);
    final tracking = delivery?['tracking_number']?.toString();

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero: package + check badge, readable without words.
                  Center(
                    child: SizedBox(
                      width: 128,
                      height: 128,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.successColor.withValues(
                                alpha: dark ? 0.2 : 0.12,
                              ),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              size: 62,
                              color: AppColors.successColor,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.successColor,
                                border: Border.all(
                                  color: HomeColors.backgroundOf(context),
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Did you receive your package?',
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
                    tracking ?? 'Delivery #${widget.deliveryId}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HomeColors.textMutedOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Summary card
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppColors.softShadow(context),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: HomeColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(24),
                        border: dark
                            ? Border.all(color: HomeColors.borderOf(context))
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InfoRow(
                            icon: Icons.trip_origin_rounded,
                            iconColor: HomeColors.violetOf(context),
                            tint: HomeColors.violetTintOf(context),
                            label: l10n.from,
                            value:
                                delivery?['pickup_location']?.toString() ?? '—',
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 25),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 2,
                                height: 14,
                                color: HomeColors.borderOf(context),
                              ),
                            ),
                          ),
                          _InfoRow(
                            icon: Icons.location_on_rounded,
                            iconColor: AppColors.successColor,
                            tint: AppColors.successColor.withValues(
                              alpha: dark ? 0.2 : 0.1,
                            ),
                            label: l10n.to,
                            value: delivery?['dropoff_location']?.toString() ??
                                '—',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Divider(
                              height: 1,
                              color: HomeColors.borderOf(context),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                l10n.deliveryDetailsStatus,
                                style: TextStyle(
                                  color: HomeColors.textMutedOf(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              StatusChip(
                                status: resolveDeliveryStatusLabel(delivery),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _PrimaryButton(
              label: 'Yes, I received it',
              icon: Icons.check_circle_rounded,
              loading: _isSubmitting,
              onPressed: _isSubmitting ? null : _confirmReceipt,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'Confirm receipt',
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: HomeColors.orange),
              )
            : _error != null
                ? _buildError(context)
                : _buildContent(context),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: HomeColors.textMutedOf(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: HomeColors.textPrimaryOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The screen's single orange call to action (56px, radius 18).
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final active = onPressed != null || loading;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: active && !HomeColors.isDark(context)
            ? [
                BoxShadow(
                  color: AppColors.brandOrange.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: active
              ? HomeColors.orange
              : HomeColors.orange.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
