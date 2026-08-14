import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/api_error_result.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import '../../../home/presentation/widgets/home_widget.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_cancel.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_payment_helper.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/screen/payment_initiate_result_screen.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';
import 'package:hudhud_delivery/features/wallet/data/providers/wallet_data_provider.dart';
import 'package:hudhud_delivery/features/wallet/data/repositories/wallet_repository.dart';
import 'package:hudhud_delivery/features/wallet/presentation/screens/add_funds_screen.dart';
import 'delivery_tracking_screen.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final int deliveryId;

  const DeliveryDetailsScreen({super.key, required this.deliveryId});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  late final CourierRepository _courierRepository;
  late final WalletRepository _walletRepository;
  Map<String, dynamic>? _delivery;
  bool _isLoading = true;
  String? _error;
  bool _isCancelling = false;
  bool _isRetrying = false;

  String get _deliveryLabel => 'DEL-${widget.deliveryId}';

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _walletRepository = WalletRepository(
      walletDataProvider: WalletDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _fetchDetails();
  }

  Future<void> _fetchDetails({bool refresh = false}) async {
    if (!refresh && mounted) {
      setState(() => _isLoading = true);
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

  String _deliveryStatus(Map<String, dynamic> d) {
    return (d['current_status'] ?? d['status'])?.toString() ?? '—';
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
          'December',
        ];
        return '${months[dt.month - 1]} ${dt.day}, ${dt.year} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return str;
  }

  String _formatCost(Map<String, dynamic> d) {
    final cost = d['estimated_cost'];
    if (cost == null) return '—';
    final amount = cost is num ? cost.toDouble() : double.tryParse('$cost');
    if (amount == null) return cost.toString();
    final currency = d['currency']?.toString() ?? 'ETB';
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CourierTheme.wrap(
        context,
        child: AlertDialog(
          backgroundColor: HomeColors.surfaceElevated,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Cancel delivery',
            style: TextStyle(color: HomeColors.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to cancel this delivery? Any payment will be refunded to your wallet.',
            style: TextStyle(color: HomeColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'No',
                style: TextStyle(color: HomeColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Yes, cancel',
                style: TextStyle(color: AppColors.errorColor),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    final result = await _courierRepository.cancelDelivery(
      deliveryId: widget.deliveryId,
    );
    if (!mounted) return;

    if (result['success'] != true) {
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? "You can't cancel this delivery",
          ),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    String successMessage =
        result['message']?.toString() ?? 'Delivery cancelled successfully';
    try {
      final balance = await _walletRepository.getBalance();
      successMessage =
          'Delivery cancelled. Wallet balance: ${balance.currency} ${balance.balance.toStringAsFixed(2)}';
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isCancelling = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: AppColors.successColor,
      ),
    );
    Navigator.pop(context);
  }

  double _topUpAmountForError(ApiErrorResult error) {
    if (error.deficit != null && error.deficit! > 0) return error.deficit!;
    final required = error.requiredAmount ?? 0;
    final balance = error.balance ?? 0;
    final computed = required - balance;
    return computed > 0 ? computed : required;
  }

  Future<void> _showInsufficientBalanceDialog(ApiErrorResult error) async {
    final topUpAmount = _topUpAmountForError(error);
    final currency = _delivery?['currency']?.toString() ?? 'ETB';
    final formattedTopUp = topUpAmount == topUpAmount.roundToDouble()
        ? topUpAmount.toStringAsFixed(0)
        : topUpAmount.toStringAsFixed(2);

    final shouldTopUp = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CourierTheme.wrap(
        context,
        child: AlertDialog(
          backgroundColor: HomeColors.surfaceElevated,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Insufficient wallet balance',
            style: TextStyle(color: HomeColors.textPrimary),
          ),
          content: Text(
            error.displayMessage,
            style: const TextStyle(color: HomeColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: HomeColors.textMuted),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Top up $currency $formattedTopUp'),
            ),
          ],
        ),
      ),
    );

    if (shouldTopUp != true || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFundsScreen(initialAmount: topUpAmount),
      ),
    );
  }

  Future<String?> _promptPaymentPhone(String paymentMethod) async {
    var details = <String, dynamic>{};
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HomeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppColors.spaceMD,
            AppColors.spaceMD,
            AppColors.spaceMD,
            MediaQuery.viewInsetsOf(sheetContext).bottom + AppColors.spaceMD,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment phone',
                style: TextStyle(
                  color: HomeColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              PaymentDetailsForm(
                paymentMethodCode: paymentMethod,
                onChanged: (value) => details = value,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: AppColors.buttonHeightMD,
                child: ElevatedButton(
                  onPressed: () {
                    final phone = retryPaymentPhone(
                      paymentMethod: paymentMethod,
                      paymentPhone: details['phone']?.toString(),
                    );
                    final error = validatePaymentPhone(phone, paymentMethod);
                    if (error != null) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(sheetContext, phone);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeColors.violet,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _retryPayment() async {
    final d = _delivery;
    if (d == null) return;

    final method = d['payment_method']?.toString() ?? '';
    if (method.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment method is missing'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    var phone = retryPaymentPhone(
      paymentMethod: method,
      paymentPhone: d['payment_phone']?.toString(),
      senderPhone: d['sender_phone']?.toString(),
    );

    if (paymentMethodNeedsDetailsForm(method) && phone.isEmpty) {
      phone = await _promptPaymentPhone(method) ?? '';
      if (!mounted) return;
      if (phone.isEmpty) return;
    }

    setState(() => _isRetrying = true);
    final result = await _courierRepository.retryPayment(
      deliveryId: widget.deliveryId,
      paymentMethod: method,
      paymentPhone: phone.isEmpty ? null : phone,
    );
    if (!mounted) return;
    setState(() => _isRetrying = false);

    if (result['success'] != true) {
      final error = result['error'] as ApiErrorResult?;
      if (error?.isInsufficientBalance == true) {
        await _showInsufficientBalanceDialog(error!);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Failed to retry payment'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final paymentResult = result['result'] as PaymentInitiateResult? ??
        const PaymentInitiateResult(
          isSuccess: true,
          uiMode: PaymentInitiateUiMode.success,
        );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentInitiateResultScreen(
          result: paymentResult,
          orderId: widget.deliveryId.toString(),
          trackingNumber: d['tracking_number']?.toString() ?? '',
          successActionLabel: 'Done',
        ),
      ),
    );
    if (mounted) await _fetchDetails(refresh: true);
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

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    const borderColor = HomeColors.border;
    final d = _delivery!;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: HomeColors.violet,
            backgroundColor: HomeColors.surface,
            onRefresh: () => _fetchDetails(refresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppColors.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryHero(
                    deliveryLabel: _deliveryLabel,
                    status: _deliveryStatus(d),
                    createdAt: _formatDate(d['created_at']),
                    cost: _formatCost(d),
                    trackingNumber: d['tracking_number']?.toString(),
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  _RouteCard(
                    pickupLabel: l10n.deliveryDetailsPickup,
                    dropoffLabel: l10n.deliveryDetailsDropoff,
                    pickupLocation: d['pickup_location']?.toString(),
                    dropoffLocation: d['dropoff_location']?.toString(),
                    pickupInstructions: d['pickup_instructions']?.toString(),
                    deliveryInstructions: d['delivery_instructions']?.toString(),
                    recipientName: d['receiver_name']?.toString(),
                    recipientPhone: d['receiver_phone']?.toString(),
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  _SectionCard(
                    title: 'Package',
                    borderColor: borderColor,
                    children: [
                      _DetailField(
                        label: 'Type',
                        value: d['package_type']?.toString(),
                      ),
                      _DetailField(
                        label: 'Description',
                        value: d['package_description']?.toString(),
                      ),
                      _DetailField(
                        label: 'Weight',
                        value: d['package_weight'] != null
                            ? '${d['package_weight']} kg'
                            : null,
                      ),
                      _DetailField(
                        label: 'Special instructions',
                        value: d['special_instructions']?.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  _SectionCard(
                    title: 'Payment',
                    borderColor: borderColor,
                    children: [
                      _DetailField(
                        label: 'Payment method',
                        value: formatPaymentMethodLabel(
                          d['payment_method']?.toString(),
                        ),
                      ),
                      _DetailField(
                        label: 'Payment status',
                        value: d['payment_status']?.toString(),
                      ),
                      _DetailField(
                        label: 'Scheduled pickup',
                        value: _formatDate(d['scheduled_pickup']),
                        hideWhenEmpty: true,
                      ),
                      _DetailField(
                        label: 'Scheduled delivery',
                        value: _formatDate(d['scheduled_delivery']),
                        hideWhenEmpty: true,
                      ),
                      _DetailField(
                        label: 'Delivered',
                        value: _formatDate(d['delivered_at']),
                        hideWhenEmpty: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                ],
              ),
            ),
          ),
        ),
        _BottomActions(
          canRetry: canRetryDeliveryPayment(
            paymentStatus: d['payment_status']?.toString(),
            paymentMethod: d['payment_method']?.toString(),
            deliveryStatus: _deliveryStatus(d),
          ),
          canCancel: canCancelCourierDelivery(_deliveryStatus(d)),
          isRetrying: _isRetrying,
          isCancelling: _isCancelling,
          onRetry: _retryPayment,
          onTrack: _navigateToTracking,
          onCancel: _cancelOrder,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final theme = Theme.of(context);

          return Scaffold(
            backgroundColor: HomeColors.background,
            appBar: AppBar(
              backgroundColor: HomeColors.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: HomeColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                _deliveryLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textPrimary,
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
                              const Icon(
                                Icons.wifi_off_rounded,
                                size: 48,
                                color: HomeColors.textMuted,
                              ),
                              const SizedBox(height: AppColors.spaceMD),
                              Text(
                                _error!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: HomeColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() => _isLoading = true);
                                  _fetchDetails();
                                },
                                icon: const Icon(Icons.refresh,
                                    color: HomeColors.violet),
                                label: Text(
                                  l10n.actionRetry,
                                  style: const TextStyle(color: HomeColors.violet),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _delivery == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppColors.spaceLG),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 112,
                                    height: 112,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: HomeColors.violet
                                          .withValues(alpha: 0.12),
                                    ),
                                    child: Icon(
                                      Icons.local_shipping_outlined,
                                      size: 56,
                                      color: HomeColors.violet
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                                  const SizedBox(height: AppColors.spaceLG),
                                  Text(
                                    'Delivery not found',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: HomeColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This delivery may have been removed or is no longer available.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: HomeColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildContent(context),
          );
        },
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.deliveryLabel,
    required this.status,
    required this.createdAt,
    required this.cost,
    this.trackingNumber,
    required this.borderColor,
  });

  final String deliveryLabel;
  final String status;
  final String createdAt;
  final String cost;
  final String? trackingNumber;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracking = trackingNumber?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: HomeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deliveryLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: HomeColors.textPrimary,
                  ),
                ),
              ),
              StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            createdAt,
            style: theme.textTheme.bodySmall?.copyWith(
              color: HomeColors.textMuted,
            ),
          ),
          if (tracking != null && tracking.isNotEmpty) ...[
            const SizedBox(height: AppColors.spaceMD),
            Text(
              'Tracking code',
              style: theme.textTheme.bodySmall?.copyWith(
                color: HomeColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    tracking,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: HomeColors.textPrimary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copyTrackingCode(context, tracking),
                  icon: const Icon(Icons.copy_rounded, color: HomeColors.violet),
                  tooltip: 'Copy tracking code',
                ),
              ],
            ),
          ],
          const SizedBox(height: AppColors.spaceMD),
          Text(
            cost,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: HomeColors.violet,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyTrackingCode(BuildContext context, String tracking) async {
    await Clipboard.setData(ClipboardData(text: tracking));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tracking code copied')),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.pickupLabel,
    required this.dropoffLabel,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupInstructions,
    this.deliveryInstructions,
    this.recipientName,
    this.recipientPhone,
    required this.borderColor,
  });

  final String pickupLabel;
  final String dropoffLabel;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? pickupInstructions;
  final String? deliveryInstructions;
  final String? recipientName;
  final String? recipientPhone;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = recipientPhone?.trim();
    final displayPhone = phone != null && phone.isNotEmpty
        ? formatPhoneForDisplay(phone)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: HomeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: HomeColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppColors.spaceMD),
          _RouteStop(
            dotColor: HomeColors.violet,
            label: pickupLabel,
            address: pickupLocation ?? '—',
            instructions: pickupInstructions,
            showConnector: true,
          ),
          _RouteStop(
            dotColor: HomeColors.orange,
            label: dropoffLabel,
            address: dropoffLocation ?? '—',
            instructions: deliveryInstructions,
            showConnector: false,
          ),
          const Divider(height: AppColors.spaceLG, color: HomeColors.border),
          _DetailField(label: 'Recipient', value: recipientName),
          _DetailField(label: 'Phone', value: displayPhone),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.dotColor,
    required this.label,
    required this.address,
    this.instructions,
    required this.showConnector,
  });

  final Color dotColor;
  final String label;
  final String address;
  final String? instructions;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = instructions?.trim();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: HomeColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 16 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: HomeColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: HomeColors.textPrimary,
                    ),
                  ),
                  if (extra != null && extra.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      extra,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: HomeColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    required this.borderColor,
  });

  final String title;
  final List<Widget> children;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: HomeColors.surfaceElevated,
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
                  color: HomeColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    this.value,
    this.hideWhenEmpty = false,
  });

  final String label;
  final String? value;
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context) {
    final v = value?.trim();
    if (hideWhenEmpty && (v == null || v.isEmpty || v == '—' || v == 'null')) {
      return const SizedBox.shrink();
    }
    if (!hideWhenEmpty && (v == null || v.isEmpty || v == 'null')) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HomeColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            v!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.canRetry,
    required this.canCancel,
    required this.isRetrying,
    required this.isCancelling,
    required this.onRetry,
    required this.onTrack,
    required this.onCancel,
  });

  final bool canRetry;
  final bool canCancel;
  final bool isRetrying;
  final bool isCancelling;
  final VoidCallback onRetry;
  final VoidCallback onTrack;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final busy = isRetrying || isCancelling;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppColors.spaceMD,
        AppColors.spaceSM,
        AppColors.spaceMD,
        AppColors.spaceMD + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: HomeColors.surface,
        border: Border(top: BorderSide(color: HomeColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canRetry) ...[
            SizedBox(
              width: double.infinity,
              height: AppColors.buttonHeightMD,
              child: OutlinedButton(
                onPressed: busy ? null : onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: HomeColors.violet,
                  side: const BorderSide(color: HomeColors.violet, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusLG),
                  ),
                ),
                child: isRetrying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: HomeColors.violet,
                        ),
                      )
                    : const Text(
                        'Retry payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppColors.spaceSM),
          ],
          SizedBox(
            width: double.infinity,
            height: AppColors.buttonHeightMD,
            child: ElevatedButton(
              onPressed: busy ? null : onTrack,
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeColors.violet,
                foregroundColor: Colors.white,
                disabledBackgroundColor: HomeColors.violet.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusLG),
                ),
              ),
              child: const Text(
                'Track delivery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (canCancel) ...[
            const SizedBox(height: AppColors.spaceSM),
            SizedBox(
              width: double.infinity,
              height: AppColors.buttonHeightMD,
              child: OutlinedButton(
                onPressed: busy ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.errorColor,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusLG),
                  ),
                ),
                child: isCancelling
                    ? const SizedBox(
                        width: 24,
                        height: 24,
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
          ],
        ],
      ),
    );
  }
}
