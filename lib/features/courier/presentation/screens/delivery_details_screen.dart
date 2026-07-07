import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/checkout/data/data_provider/checkout_data_provider.dart';
import 'package:hudhud_delivery/features/checkout/data/repository/checkout_repository.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_navigation.dart';
import 'package:hudhud_delivery/features/guest/utils/guest_sign_in_prompt.dart';
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
    if (!await requireSignInForBackend(context)) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Sign in required';
        });
      }
      return;
    }
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

  bool _hasAssignedDriver(Map<String, dynamic> delivery) {
    final driver = delivery['driver'];
    return driver != null && driver is Map && driver.isNotEmpty;
  }

  void _openDriverChat() {
    if (_delivery == null || !_hasAssignedDriver(_delivery!)) return;
    openPackageDeliveryChat(context, widget.deliveryId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delivery #${widget.deliveryId}',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _delivery == null
                  ? const Center(child: Text('Delivery not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailCard(
                            title: 'Status',
                            child: _StatusChip(
                              status: (_delivery!['current_status'] ??
                                          _delivery!['status'])
                                      ?.toString() ??
                                  '—',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailCard(
                            title: 'Pickup',
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
                            title: 'Dropoff',
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
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  _isCancelling ? null : _navigateToTracking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Track Delivery',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (_delivery != null &&
                              _hasAssignedDriver(_delivery!)) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _openDriverChat,
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Message driver'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: AppColors.primaryColor,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _isCancelling ? null : _cancelOrder,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isCancelling
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.red[400],
                                      ),
                                    )
                                  : Text(
                                      'Cancel Order',
                                      style: TextStyle(
                                        color: Colors.red[700],
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

  const _DetailCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
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
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
    );
  }
}
