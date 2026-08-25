import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final delivery = _delivery;

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
            'Confirm receipt',
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: HomeColors.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(onPressed: _loadDelivery, child: Text(context.l10n.actionRetry)),
                        ],
                      ),
                    ),
                  )
                : Padding(
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
                                'Did you receive your package?',
                                style: TextStyle(
                                  color: HomeColors.textPrimaryOf(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                delivery?['tracking_number']?.toString() ??
                                    'Delivery #${widget.deliveryId}',
                                style: TextStyle(
                                  color: HomeColors.textSecondaryOf(context),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _InfoRow(
                                label: 'From',
                                value: delivery?['pickup_location']?.toString() ?? '—',
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'To',
                                value: delivery?['dropoff_location']?.toString() ?? '—',
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Status',
                                value: resolveDeliveryStatusLabel(delivery),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: AppColors.buttonHeightMD,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _confirmReceipt,
                            style: FilledButton.styleFrom(
                              backgroundColor: HomeColors.violet,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Yes, I received it',
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              color: HomeColors.textMutedOf(context),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
