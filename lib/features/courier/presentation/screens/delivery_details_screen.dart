import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import '../../../home/presentation/widgets/home_widget.dart';
import 'package:hudhud_delivery/features/checkout/data/data_provider/checkout_data_provider.dart';
import 'package:hudhud_delivery/features/checkout/data/repository/checkout_repository.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'delivery_tracking_screen.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final int deliveryId;

  const DeliveryDetailsScreen({super.key, required this.deliveryId});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  late final CourierRepository _courierRepository;
  late final CheckoutRepository _checkoutRepository;
  Map<String, dynamic>? _delivery;
  bool _isLoading = true;
  String? _error;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _checkoutRepository = CheckoutRepository(
      checkoutDataProvider: CheckoutDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final result =
          await _courierRepository.getUserDeliveryDetails(widget.deliveryId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true) {
            _delivery = result['data'] as Map<String, dynamic>?;
            _error = null;
          } else {
            _delivery = null;
            _error = result['message'] as String?;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _delivery = null;
          _error = 'Failed to load delivery details';
        });
      }
    }
  }

  LatLng? _parseLatLng(dynamic lat, dynamic lng) {
    final latVal =
        lat is num ? lat.toDouble() : double.tryParse(lat?.toString() ?? '');
    final lngVal =
        lng is num ? lng.toDouble() : double.tryParse(lng?.toString() ?? '');
    if (latVal != null && lngVal != null) return LatLng(latVal, lngVal);
    return null;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    final str = value.toString();
    try {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        return '${months[dt.month - 1]} ${dt.day}, ${dt.year} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return str;
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    final result = await _checkoutRepository.cancelOrder(widget.deliveryId);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result['message']?.toString() ?? 'Order cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result['message']?.toString() ?? "You can't cancel this order"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToTracking() {
    if (_delivery == null) return;
    final d = _delivery!;
    final pickupPos = _parseLatLng(d['pickup_latitude'], d['pickup_longitude']);
    final dropoffPos =
        _parseLatLng(d['dropoff_latitude'], d['dropoff_longitude']);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryTrackingScreen(
          deliveryId: widget.deliveryId,
          pickupLocation: d['pickup_location']?.toString() ?? '',
          deliveryLocation: d['dropoff_location']?.toString() ?? '',
          pickupPosition: pickupPos,
          deliveryPosition: dropoffPos,
          selectedVehicle: d['vehicle_type']?.toString() ?? 'motorbike',
          itemType: d['package_type']?.toString() ?? '',
          quantity: d['package_weight']?.toString() ?? '1',
          whoPays: 'me',
          paymentType: d['payment_method']?.toString() ?? 'cash',
          recipientName: d['receiver_name']?.toString() ?? '',
          recipientPhone: d['receiver_phone']?.toString() ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delivery #${widget.deliveryId}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(AppColors.spaceMD),
              child: ShimmerListView(itemCount: 4),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.spaceLG),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppColors.spaceMD),
                        Text(
                          _error!,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _fetchDetails();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.actionRetry),
                        ),
                      ],
                    ),
                  ),
                )
              : _delivery == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('assets/animations/browse.json',
                            width: 180),
                        const SizedBox(height: AppColors.spaceMD),
                        Text(
                          'Delivery not found',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppColors.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailCard(
                            title: l10n.deliveryDetailsStatus,
                            borderColor: borderColor,
                            child: StatusChip(
                              status: (_delivery!['current_status'] ??
                                          _delivery!['status'])
                                      ?.toString() ??
                                  '—',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailCard(
                            title: l10n.deliveryDetailsPickup,
                            borderColor: borderColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  label: 'Location',
                                  value:
                                      _delivery!['pickup_location']?.toString(),
                                ),
                                if (_delivery!['pickup_instructions'] != null &&
                                    _delivery!['pickup_instructions']
                                        .toString()
                                        .isNotEmpty)
                                  _DetailRow(
                                    label: 'Instructions',
                                    value: _delivery!['pickup_instructions']
                                        ?.toString(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailCard(
                            title: l10n.deliveryDetailsDropoff,
                            borderColor: borderColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  label: 'Location',
                                  value: _delivery!['dropoff_location']
                                      ?.toString(),
                                ),
                                _DetailRow(
                                  label: 'Receiver',
                                  value:
                                      _delivery!['receiver_name']?.toString(),
                                ),
                                _DetailRow(
                                  label: 'Phone',
                                  value:
                                      _delivery!['receiver_phone']?.toString(),
                                ),
                                if (_delivery!['delivery_instructions'] !=
                                        null &&
                                    _delivery!['delivery_instructions']
                                        .toString()
                                        .isNotEmpty)
                                  _DetailRow(
                                    label: 'Instructions',
                                    value: _delivery!['delivery_instructions']
                                        ?.toString(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailCard(
                            title: 'Package',
                            borderColor: borderColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  label: 'Type',
                                  value: _delivery!['package_type']?.toString(),
                                ),
                                if (_delivery!['package_description'] != null &&
                                    _delivery!['package_description']
                                        .toString()
                                        .isNotEmpty)
                                  _DetailRow(
                                    label: 'Description',
                                    value: _delivery!['package_description']
                                        ?.toString(),
                                  ),
                                _DetailRow(
                                  label: 'Weight',
                                  value:
                                      _delivery!['package_weight']?.toString(),
                                ),
                                if (_delivery!['special_instructions'] !=
                                        null &&
                                    _delivery!['special_instructions']
                                        .toString()
                                        .isNotEmpty)
                                  _DetailRow(
                                    label: 'Special instructions',
                                    value: _delivery!['special_instructions']
                                        ?.toString(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailCard(
                            title: 'Payment & Cost',
                            borderColor: borderColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  label: 'Payment method',
                                  value:
                                      _delivery!['payment_method']?.toString(),
                                ),
                                _DetailRow(
                                  label: 'Estimated cost',
                                  value:
                                      _delivery!['estimated_cost']?.toString(),
                                ),
                                _DetailRow(
                                  label: 'Payment status',
                                  value:
                                      _delivery!['payment_status']?.toString(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailCard(
                            title: 'Timeline',
                            borderColor: borderColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  label: 'Created',
                                  value: _formatDate(_delivery!['created_at']),
                                ),
                                if (_delivery!['scheduled_pickup'] != null)
                                  _DetailRow(
                                    label: 'Scheduled pickup',
                                    value: _formatDate(
                                        _delivery!['scheduled_pickup']),
                                  ),
                                if (_delivery!['scheduled_delivery'] != null)
                                  _DetailRow(
                                    label: 'Scheduled delivery',
                                    value: _formatDate(
                                        _delivery!['scheduled_delivery']),
                                  ),
                                if (_delivery!['delivered_at'] != null)
                                  _DetailRow(
                                    label: 'Delivered',
                                    value:
                                        _formatDate(_delivery!['delivered_at']),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: AppColors.buttonHeightMD,
                            child: ElevatedButton(
                              onPressed:
                                  _isCancelling ? null : _navigateToTracking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppColors.radiusLG),
                                ),
                              ),
                              child: const Text(
                                'Track Delivery',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: AppColors.buttonHeightMD,
                            child: OutlinedButton(
                              onPressed: _isCancelling ? null : _cancelOrder,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.errorColor,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppColors.radiusLG),
                                ),
                              ),
                              child: _isCancelling
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.errorColor,
                                      ),
                                    )
                                  : Text(
                                      'Cancel Order',
                                      style: TextStyle(
                                        color: AppColors.errorColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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

class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color borderColor;

  const _DetailCard({
    required this.title,
    required this.child,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = value?.trim();
    if (v == null || v.isEmpty || v == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
