import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import '../../../home/presentation/widgets/home_widget.dart';
import 'package:hudhud_delivery/features/checkout/presentation/widgets/checkout_widgets.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_cancel.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_payment_helper.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_home_refresh.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_live_job_screen.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/model/payment_initiate_result.dart';
import 'package:hudhud_delivery/features/payment/presentation/screen/payment_initiate_result_screen.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_details_form.dart';
import 'package:hudhud_delivery/features/payment/presentation/widgets/payment_methods_loader.dart';
import 'package:hudhud_delivery/features/wallet/presentation/screens/add_funds_screen.dart';

class _RetryPaymentChoice {
  const _RetryPaymentChoice({
    required this.method,
    this.phone = '',
  });

  final String method;
  final String phone;
}

class DeliveryDetailsScreen extends StatefulWidget {
  final int deliveryId;

  const DeliveryDetailsScreen({super.key, required this.deliveryId});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  late final CourierRepository _courierRepository;
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
    return resolveDeliveryStatusLabel(d);
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
    final paymentStatus = _delivery?['payment_status']?.toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CourierTheme.wrap(
        context,
        child: AlertDialog(
          backgroundColor: HomeColors.surfaceElevatedOf(context),
          surfaceTintColor: Colors.transparent,
          title: Text(
            context.l10n.cancelDeliveryTitle,
            style: TextStyle(color: HomeColors.textPrimaryOf(context)),
          ),
          content: Text(
            cancelDeliveryConfirmMessage(
              context.l10n,
              paymentStatus: paymentStatus,
            ),
            style: TextStyle(color: HomeColors.textSecondaryOf(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                context.l10n.actionNo,
                style: TextStyle(color: HomeColors.textMutedOf(context)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                context.l10n.actionYesCancel,
                style: const TextStyle(color: AppColors.errorColor),
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

    final refund = parseDeliveryCancelRefundResponse(result['data'] ?? result);
    final successMessage = formatDeliveryCancelMessage(refund);

    if (!mounted) return;
    setState(() => _isCancelling = false);
    CourierHomeRefresh.instance.notifyRefresh();
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
          backgroundColor: HomeColors.surfaceElevatedOf(context),
          surfaceTintColor: Colors.transparent,
          title: Text(
            context.l10n.insufficientWalletBalance,
            style: TextStyle(color: HomeColors.textPrimaryOf(context)),
          ),
          content: Text(
            error.displayMessage,
            style: TextStyle(color: HomeColors.textSecondaryOf(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                context.l10n.actionCancel,
                style: TextStyle(color: HomeColors.textMutedOf(context)),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.topUpAmount(currency, formattedTopUp)),
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

  /// Payment methods eligible for unpaid delivery retry (no COD).
  List<Map<String, dynamic>> _retryPaymentMethods(
    List<Map<String, dynamic>> methods,
  ) {
    final filtered = filterAllowedPaymentMethods(methods).where((m) {
      final id = m['id']?.toString() ?? '';
      return id.isNotEmpty &&
          id != 'cash_on_delivery' &&
          id != 'cash' &&
          m['enabled'] != false;
    }).toList(growable: false);
    if (filtered.isNotEmpty) return filtered;
    return filterAllowedPaymentMethods(
      List<Map<String, dynamic>>.from(kDefaultAllowedPaymentMethods),
    ).where((m) {
      final id = m['id']?.toString() ?? '';
      return id != 'cash_on_delivery' && id != 'cash';
    }).toList(growable: false);
  }

  Future<_RetryPaymentChoice?> _promptRetryPaymentSelection({
    String? initialMethod,
    String? initialPhone,
  }) async {
    return showModalBottomSheet<_RetryPaymentChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HomeColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return PaymentMethodsLoader(
          repository: PaymentRepository(
            paymentDataProvider: PaymentDataProvider(
              apiService: ApiService.instance,
            ),
          ),
          builder: (context, methods, isLoading, error, reload) {
            return _RetryPaymentSheet(
              methods: _retryPaymentMethods(methods),
              isLoading: isLoading,
              error: error,
              onReload: reload,
              initialMethod: initialMethod,
              initialPhone: initialPhone,
            );
          },
        );
      },
    );
  }

  Future<void> _retryPayment() async {
    final d = _delivery;
    if (d == null) return;

    final previousMethod = d['payment_method']?.toString();
    final previousPhone = retryPaymentPhone(
      paymentMethod: previousMethod ?? '',
      paymentPhone: d['payment_phone']?.toString(),
      senderPhone: d['sender_phone']?.toString(),
    );

    final choice = await _promptRetryPaymentSelection(
      initialMethod: previousMethod,
      initialPhone: previousPhone.isEmpty ? null : previousPhone,
    );
    if (!mounted) return;
    if (choice == null) return;

    final method = choice.method;
    final phone = choice.phone;

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
      if (error?.isAmountMismatch == true) {
        await _fetchDetails(refresh: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error!.displayMessage.isNotEmpty
                  ? error.displayMessage
                  : 'Payment amount changed. Review the updated total and try again.',
            ),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
      if (error?.isDeliveryPaymentRetryFailed == true ||
          error?.statusCode == 502) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error!.displayMessage.isNotEmpty
                  ? error.displayMessage
                  : 'Delivery payment could not be initiated. Please try again.',
            ),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result['message']?.toString() ?? 'Failed to retry payment'),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => courierLiveJobScreenFromDelivery(_delivery!),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    final borderColor = HomeColors.borderOf(context);
    final d = _delivery!;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.brandOrange,
            backgroundColor: HomeColors.surfaceOf(context),
            onRefresh: () => _fetchDetails(refresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  const SizedBox(height: 14),
                  _RouteCard(
                    pickupLabel: l10n.deliveryDetailsPickup,
                    dropoffLabel: l10n.deliveryDetailsDropoff,
                    pickupLocation: d['pickup_location']?.toString(),
                    dropoffLocation: d['dropoff_location']?.toString(),
                    pickupInstructions: d['pickup_instructions']?.toString(),
                    deliveryInstructions:
                        d['delivery_instructions']?.toString(),
                    recipientName: d['receiver_name']?.toString(),
                    recipientPhone: d['receiver_phone']?.toString(),
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Package',
                    icon: Icons.inventory_2_rounded,
                    accent: AppColors.brandOrange,
                    borderColor: borderColor,
                    children: [
                      _DetailField(
                        icon: Icons.category_rounded,
                        label: 'Type',
                        value: d['package_type']?.toString(),
                      ),
                      _DetailField(
                        icon: Icons.notes_rounded,
                        label: 'Description',
                        value: d['package_description']?.toString(),
                      ),
                      _DetailField(
                        icon: Icons.scale_rounded,
                        label: 'Weight',
                        value: d['package_weight'] != null
                            ? '${d['package_weight']} kg'
                            : null,
                      ),
                      _DetailField(
                        icon: Icons.info_outline_rounded,
                        label: 'Special instructions',
                        value: d['special_instructions']?.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Payment',
                    icon: Icons.payments_rounded,
                    accent: HomeColors.violetOf(context),
                    borderColor: borderColor,
                    children: [
                      _DetailField(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Payment method',
                        value: formatPaymentMethodLabel(
                          d['payment_method']?.toString(),
                        ),
                      ),
                      _DetailField(
                        icon: Icons.verified_rounded,
                        label: 'Payment status',
                        value: d['payment_status']?.toString(),
                        trailingStatus: true,
                      ),
                      _DetailField(
                        icon: Icons.event_rounded,
                        label: 'Scheduled pickup',
                        value: _formatDate(d['scheduled_pickup']),
                        hideWhenEmpty: true,
                      ),
                      _DetailField(
                        icon: Icons.event_available_rounded,
                        label: 'Scheduled delivery',
                        value: _formatDate(d['scheduled_delivery']),
                        hideWhenEmpty: true,
                      ),
                      _DetailField(
                        icon: Icons.check_circle_rounded,
                        label: 'Delivered',
                        value: _formatDate(d['delivered_at']),
                        hideWhenEmpty: true,
                      ),
                    ],
                  ),
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
          canTrack: canTrackCourierDelivery(_deliveryStatus(d)),
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

  Widget _stateMessage(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color tint,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
              child: Icon(icon, size: 46, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textMutedOf(context),
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final dark = HomeColors.isDark(context);
          final bg = HomeColors.backgroundOf(context);

          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 26,
                  color: HomeColors.textPrimaryOf(context),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                _deliveryLabel,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: HomeColors.textPrimaryOf(context),
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
                    ? _stateMessage(
                        context,
                        icon: Icons.wifi_off_rounded,
                        color: AppColors.errorColor,
                        tint: AppColors.errorColor.withValues(
                          alpha: dark ? 0.2 : 0.1,
                        ),
                        title: _error!,
                        action: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () {
                              setState(() => _isLoading = true);
                              _fetchDetails();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 24),
                            label: Text(
                              l10n.actionRetry,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      )
                    : _delivery == null
                        ? _stateMessage(
                            context,
                            icon: Icons.local_shipping_rounded,
                            color: HomeColors.violetOf(context),
                            tint: HomeColors.violetTintOf(context),
                            title: 'Delivery not found',
                            subtitle:
                                'This delivery may have been removed or is no longer available.',
                          )
                        : _buildContent(context),
          );
        },
      ),
    );
  }
}

/// Surface card with soft shadow (light) or hairline border (dark).
class _CardShell extends StatelessWidget {
  const _CardShell({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(22);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: dark ? BorderSide(color: borderColor) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// 52px rounded icon tile with a soft tint of [color].
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    this.size = 52,
    this.iconSize = 26,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(size * 0.31),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconTile(icon: icon, color: color, size: 44, iconSize: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
        ),
      ],
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
    final tracking = trackingNumber?.trim();
    final muted = HomeColors.textMutedOf(context);
    final statusColor = StatusChip.colorForStatus(status);

    return _CardShell(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(icon: Icons.inventory_2_rounded, color: statusColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliveryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: HomeColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      createdAt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: status),
            ],
          ),
          if (tracking != null && tracking.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
              decoration: BoxDecoration(
                color: HomeColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 24, color: muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tracking code',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tracking,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: HomeColors.textPrimaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyTrackingCode(context, tracking),
                    iconSize: 24,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(
                      Icons.copy_rounded,
                      color: HomeColors.violetOf(context),
                    ),
                    tooltip: 'Copy tracking code',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.payments_rounded, size: 24, color: muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cost,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyTrackingCode(BuildContext context, String tracking) async {
    await Clipboard.setData(ClipboardData(text: tracking));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.trackingCodeCopied)),
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
    final phone = recipientPhone?.trim();
    final displayPhone =
        phone != null && phone.isNotEmpty ? formatPhoneForDisplay(phone) : null;

    return _CardShell(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.route_rounded,
            color: HomeColors.violetOf(context),
            title: 'Route',
          ),
          const SizedBox(height: 16),
          _RouteStop(
            icon: Icons.trip_origin_rounded,
            color: AppColors.brandOrange,
            label: pickupLabel,
            address: pickupLocation ?? '—',
            instructions: pickupInstructions,
            showConnector: true,
          ),
          _RouteStop(
            icon: Icons.location_on_rounded,
            color: HomeColors.violetOf(context),
            label: dropoffLabel,
            address: dropoffLocation ?? '—',
            instructions: deliveryInstructions,
            showConnector: false,
          ),
          Divider(height: 28, color: HomeColors.borderOf(context)),
          _DetailField(
            icon: Icons.person_rounded,
            label: 'Recipient',
            value: recipientName,
          ),
          _DetailField(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: displayPhone,
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
    this.instructions,
    required this.showConnector,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String address;
  final String? instructions;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final extra = instructions?.trim();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                _IconTile(icon: icon, color: color, size: 44, iconSize: 22),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: HomeColors.borderOf(context),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: showConnector ? 18 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.textMutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.textPrimaryOf(context),
                    ),
                  ),
                  if (extra != null && extra.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      extra,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HomeColors.textSecondaryOf(context),
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
    required this.icon,
    required this.accent,
    required this.children,
    required this.borderColor,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<Widget> children;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: icon, color: accent, title: title),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.icon,
    required this.label,
    this.value,
    this.hideWhenEmpty = false,
    this.trailingStatus = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool hideWhenEmpty;

  /// Render the value as a [StatusChip] instead of plain text.
  final bool trailingStatus;

  @override
  Widget build(BuildContext context) {
    final v = value?.trim();
    if (hideWhenEmpty && (v == null || v.isEmpty || v == '—' || v == 'null')) {
      return const SizedBox.shrink();
    }
    if (!hideWhenEmpty && (v == null || v.isEmpty || v == 'null')) {
      return const SizedBox.shrink();
    }
    final muted = HomeColors.textMutedOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: HomeColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 3),
                if (trailingStatus)
                  StatusChip(status: v!)
                else
                  Text(
                    v!,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.textPrimaryOf(context),
                    ),
                  ),
              ],
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
    required this.canTrack,
    required this.canCancel,
    required this.isRetrying,
    required this.isCancelling,
    required this.onRetry,
    required this.onTrack,
    required this.onCancel,
  });

  final bool canRetry;
  final bool canTrack;
  final bool canCancel;
  final bool isRetrying;
  final bool isCancelling;
  final VoidCallback onRetry;
  final VoidCallback onTrack;
  final VoidCallback onCancel;

  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
  );
  static const _labelStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  Widget _spinner(Color color) => SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
      );

  @override
  Widget build(BuildContext context) {
    final busy = isRetrying || isCancelling;
    if (!canRetry && !canTrack && !canCancel) {
      return const SizedBox.shrink();
    }
    final dark = HomeColors.isDark(context);
    final indigo = HomeColors.violetOf(context);
    // Only one orange primary: tracking wins; otherwise retry payment.
    final retryIsPrimary = canRetry && !canTrack;

    Widget primary({
      required VoidCallback onPressed,
      required IconData icon,
      required String label,
      required bool loading,
    }) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandOrange,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.brandOrange.withValues(alpha: 0.45),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: _shape,
          ),
          icon: loading ? _spinner(Colors.white) : Icon(icon, size: 24),
          label: Text(label, style: _labelStyle),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        border: dark
            ? Border(top: BorderSide(color: HomeColors.borderOf(context)))
            : null,
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x121B1530),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canTrack) ...[
            primary(
              onPressed: onTrack,
              icon: Icons.near_me_rounded,
              label: context.l10n.courierTrackDeliveryCta,
              loading: false,
            ),
            if (canRetry || canCancel) const SizedBox(height: 10),
          ],
          if (canRetry) ...[
            if (retryIsPrimary)
              primary(
                onPressed: onRetry,
                icon: Icons.payments_rounded,
                label: context.l10n.retryPaymentTitle,
                loading: isRetrying,
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: indigo,
                    side: BorderSide(color: indigo, width: 1.5),
                    shape: _shape,
                  ),
                  icon: isRetrying
                      ? _spinner(indigo)
                      : const Icon(Icons.payments_rounded, size: 24),
                  label: Text(
                    context.l10n.retryPaymentTitle,
                    style: _labelStyle,
                  ),
                ),
              ),
            if (canCancel) const SizedBox(height: 10),
          ],
          if (canCancel)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton.icon(
                onPressed: busy ? null : onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorColor,
                  shape: _shape,
                  side: BorderSide(
                    color: AppColors.errorColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                icon: isCancelling
                    ? _spinner(AppColors.errorColor)
                    : const Icon(Icons.close_rounded, size: 24),
                label: Text(
                  context.l10n.cancelDeliveryTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RetryPaymentSheet extends StatefulWidget {
  const _RetryPaymentSheet({
    required this.methods,
    required this.isLoading,
    required this.onReload,
    this.error,
    this.initialMethod,
    this.initialPhone,
  });

  final List<Map<String, dynamic>> methods;
  final bool isLoading;
  final String? error;
  final VoidCallback onReload;
  final String? initialMethod;
  final String? initialPhone;

  @override
  State<_RetryPaymentSheet> createState() => _RetryPaymentSheetState();
}

class _RetryPaymentSheetState extends State<_RetryPaymentSheet> {
  String? _selectedMethod;
  Map<String, dynamic> _paymentDetails = {};
  String _ebirrProvider = 'kaafi';
  bool _useHpp = false;

  @override
  void initState() {
    super.initState();
    _applySelection(widget.methods);
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      _paymentDetails = {'phone': widget.initialPhone};
    }
  }

  @override
  void didUpdateWidget(covariant _RetryPaymentSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.methods != widget.methods ||
        oldWidget.isLoading != widget.isLoading) {
      final before = _selectedMethod;
      _applySelection(widget.methods);
      if (before != _selectedMethod) {
        setState(() {});
      }
    }
  }

  void _applySelection(List<Map<String, dynamic>> methods) {
    if (methods.isEmpty) return;
    final preferred = widget.initialMethod;
    final hasPreferred =
        preferred != null && methods.any((m) => m['id'] == preferred);
    final next = hasPreferred
        ? preferred
        : (_selectedMethod != null &&
                methods.any((m) => m['id'] == _selectedMethod)
            ? _selectedMethod
            : methods.first['id']?.toString());
    if (next == _selectedMethod) return;
    _selectedMethod = next;
    if (!hasPreferred || next != preferred) {
      _paymentDetails = {};
      _useHpp = false;
      _ebirrProvider = 'kaafi';
    }
  }

  void _submit() {
    final method = _selectedMethod;
    if (method == null || method.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.paymentSelectMethodFirst),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    var phone = '';
    if (paymentMethodNeedsDetailsForm(method)) {
      phone = retryPaymentPhone(
        paymentMethod: method,
        paymentPhone: _paymentDetails['phone']?.toString(),
      );
      final error = validatePaymentPhone(phone, method);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }
    }

    Navigator.pop(
      context,
      _RetryPaymentChoice(method: method, phone: phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppColors.spaceMD,
        AppColors.spaceMD,
        AppColors.spaceMD,
        MediaQuery.viewInsetsOf(context).bottom + AppColors.spaceMD,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: HomeColors.borderOf(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              context.l10n.retryPaymentTitle,
              style: TextStyle(
                color: HomeColors.textPrimaryOf(context),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.retryPaymentSubtitle,
              style: TextStyle(
                color: HomeColors.textMutedOf(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.error != null && widget.methods.isEmpty) ...[
              Text(
                context.l10n.paymentLoadMethodsError,
                style: const TextStyle(color: AppColors.errorColor),
              ),
              TextButton(
                onPressed: widget.onReload,
                child: Text(context.l10n.actionRetry),
              ),
            ] else ...[
              PaymentMethodGridSection(
                selectedId: _selectedMethod,
                methods: widget.methods,
                isLoading: widget.isLoading,
                onSelected: (id) {
                  setState(() {
                    _selectedMethod = id;
                    _paymentDetails = {};
                    _useHpp = false;
                    _ebirrProvider = 'kaafi';
                  });
                },
              ),
              if (_selectedMethod != null &&
                  paymentMethodNeedsDetailsForm(_selectedMethod!)) ...[
                const SizedBox(height: 12),
                PaymentDetailsForm(
                  key: ValueKey(_selectedMethod),
                  paymentMethodCode: _selectedMethod!,
                  initialPhone: _paymentDetails['phone']?.toString() ??
                      (_selectedMethod == widget.initialMethod
                          ? widget.initialPhone
                          : null),
                  ebirrProvider: _ebirrProvider,
                  useHpp: _useHpp,
                  onEbirrProviderChanged: (v) =>
                      setState(() => _ebirrProvider = v),
                  onUseHppChanged: (v) => setState(() => _useHpp = v),
                  onChanged: (details) {
                    _paymentDetails = details;
                  },
                ),
              ],
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomeColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(context.l10n.actionContinue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
