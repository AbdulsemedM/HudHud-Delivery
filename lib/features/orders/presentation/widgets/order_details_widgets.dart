import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/core/widgets/section_header.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_tracking_model.dart';
import '../widgets/orders_widget.dart';

class OrderDetailsShimmer extends StatelessWidget {
  const OrderDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor =
        isDark ? theme.colorScheme.surfaceContainerHigh : Colors.grey.shade300;
    final highlightColor =
        isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade100;
    final placeholder = isDark ? AppColors.surfaceDark : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: placeholder,
              borderRadius: BorderRadius.circular(AppColors.r12),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 140,
              decoration: BoxDecoration(
                color: placeholder,
                borderRadius: BorderRadius.circular(14),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class OrderTrackingStepper extends StatelessWidget {
  const OrderTrackingStepper({
    super.key,
    required this.order,
    this.tracking,
  });

  final OrderModel order;
  final OrderTrackingModel? tracking;

  List<_TrackingStep> _buildSteps(BuildContext context) {
    final l10n = context.l10n;
    final isCancelled = order.isCancelled;

    return [
      _TrackingStep(
        title: l10n.timelineOrderPlaced,
        time: order.formattedCreatedAt,
        state: _StepState.completed,
        icon: Icons.shopping_cart_outlined,
      ),
      _TrackingStep(
        title: l10n.timelineOrderConfirmed,
        time: order.confirmedAt != null ? order.formattedConfirmedAt : null,
        state: isCancelled
            ? _StepState.upcoming
            : order.isConfirmed
                ? _StepState.completed
                : order.isPending
                    ? _StepState.active
                    : _StepState.upcoming,
        icon: Icons.check_circle_outline_rounded,
      ),
      _TrackingStep(
        title: l10n.timelinePreparing,
        time: order.preparingAt != null ? order.formattedPreparingAt : null,
        state: isCancelled
            ? _StepState.upcoming
            : order.isPreparing ||
                    order.isReadyForPickup ||
                    order.isOutForDelivery ||
                    order.isDelivered
                ? _StepState.completed
                : order.isConfirmed
                    ? _StepState.active
                    : _StepState.upcoming,
        icon: Icons.restaurant_rounded,
      ),
      _TrackingStep(
        title: l10n.timelineOutDelivery,
        time: order.outForDeliveryAt != null
            ? order.formattedOutForDeliveryAt
            : tracking?.estimatedTime,
        state: isCancelled
            ? _StepState.upcoming
            : order.isOutForDelivery || order.isDelivered
                ? _StepState.completed
                : order.isReadyForPickup || order.isPreparing
                    ? _StepState.active
                    : _StepState.upcoming,
        icon: Icons.local_shipping_outlined,
      ),
      _TrackingStep(
        title: l10n.timelineDelivered,
        time: order.deliveredAt != null ? order.formattedDeliveredAt : null,
        state: isCancelled
            ? _StepState.cancelled
            : order.isDelivered
                ? _StepState.completed
                : _StepState.upcoming,
        icon: Icons.done_all_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final steps = _buildSteps(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: context.l10n.timeline),
            const SizedBox(height: 8),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;
              return _TrackingStepRow(
                step: step,
                isLast: isLast,
                muted: muted,
              );
            }),
          ],
        ),
      ),
    );
  }
}

enum _StepState { completed, active, upcoming, cancelled }

class _TrackingStep {
  const _TrackingStep({
    required this.title,
    required this.state,
    required this.icon,
    this.time,
  });

  final String title;
  final String? time;
  final _StepState state;
  final IconData icon;
}

class _TrackingStepRow extends StatelessWidget {
  const _TrackingStepRow({
    required this.step,
    required this.isLast,
    required this.muted,
  });

  final _TrackingStep step;
  final bool isLast;
  final Color muted;

  Color _circleColor() {
    switch (step.state) {
      case _StepState.completed:
        return AppColors.delivered;
      case _StepState.active:
        return AppColors.primaryColor;
      case _StepState.cancelled:
        return AppColors.cancelled;
      case _StepState.upcoming:
        return AppColors.mutedLight;
    }
  }

  Color _lineColor() {
    return step.state == _StepState.completed
        ? AppColors.delivered.withOpacity(0.5)
        : muted.withOpacity(0.35);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final circleColor = _circleColor();
    final isActive = step.state == _StepState.active;
    final isCompleted = step.state == _StepState.completed;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: isActive ? 30 : 26,
                  height: isActive ? 30 : 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isActive
                        ? circleColor
                        : Colors.transparent,
                    border: Border.all(
                      color: circleColor,
                      width: isActive ? 2.5 : 2,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : step.icon,
                    size: isActive ? 16 : 14,
                    color: isCompleted || isActive
                        ? AppColors.lightOnPrimary
                        : muted,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: _lineColor(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
                      color: step.state == _StepState.upcoming
                          ? muted
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (step.time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.time!,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
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

class PackageInfoCard extends StatelessWidget {
  const PackageInfoCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return _InfoCard(
      title: l10n.labelPackage,
      icon: Icons.inventory_2_outlined,
      iconColor: AppColors.confirmed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.r10),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: order.vendor.logo != null
                      ? Image.network(
                          order.vendor.logo!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: AppColors.confirmed.withOpacity(0.1),
                            child: const Icon(Icons.store_rounded),
                          ),
                        )
                      : ColoredBox(
                          color: AppColors.confirmed.withOpacity(0.1),
                          child: const Icon(Icons.store_rounded),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.vendor.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.items.length} ${l10n.quantity.toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              StatusChip(
                status: localizedOrderStatus(context, order.status),
              ),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...order.items.take(2).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${item.quantity}x ${item.product?.name ?? item.productName}',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class RouteInfoCard extends StatelessWidget {
  const RouteInfoCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return _InfoCard(
      title: l10n.actionTrackDelivery,
      icon: Icons.route_rounded,
      iconColor: AppColors.onTheWay,
      child: Column(
        children: [
          _RoutePoint(
            label: l10n.deliveryDetailsPickup,
            value: order.vendor.name,
            icon: Icons.store_rounded,
            iconColor: AppColors.confirmed,
            muted: muted,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 20,
                color: muted.withOpacity(0.35),
              ),
            ),
          ),
          _RoutePoint(
            label: l10n.deliveryDetailsDropoff,
            value: order.deliveryAddress,
            icon: Icons.location_on_rounded,
            iconColor: AppColors.primaryColor,
            muted: muted,
          ),
          if (order.driver != null) ...[
            const SizedBox(height: 12),
            Divider(color: muted.withOpacity(0.25)),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(order.driver!.avatar),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.driver!.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        order.driver!.phone,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.muted,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBox(icon: icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PaymentInfoCard extends StatelessWidget {
  const PaymentInfoCard({super.key, required this.order});

  final OrderModel order;

  String _paymentStatusLabel(BuildContext context) {
    final l10n = context.l10n;
    return order.paymentMethod == 'cash'
        ? l10n.paymentCashOnDelivery
        : l10n.paymentPaidOnline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return _InfoCard(
      title: l10n.payment,
      icon: Icons.payments_outlined,
      iconColor: AppColors.primaryColor,
      child: Column(
        children: [
          _PaymentRow(
            label: l10n.paymentMethod,
            value: order.paymentMethod,
            muted: muted,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.labelPaymentStatus,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              StatusChip(status: _paymentStatusLabel(context)),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: muted.withOpacity(0.25)),
          const SizedBox(height: 8),
          _PaymentRow(
            label: l10n.paymentSubtotalLabel,
            value: order.formattedSubtotal,
            muted: muted,
          ),
          const SizedBox(height: 6),
          _PaymentRow(
            label: l10n.paymentTotalAmountLabel,
            value: order.formattedTotal,
            muted: muted,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.value,
    required this.muted,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color muted;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: emphasized ? theme.colorScheme.onSurface : muted,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
            color: emphasized ? AppColors.primaryColor : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBox(icon: icon, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: SectionHeader(title: title),
                ),
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

class OrderItemsCard extends StatelessWidget {
  final List<OrderItemModel> items;

  const OrderItemsCard({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: '${context.l10n.orders} (${items.length})'),
            const SizedBox(height: 8),
            ...items.map((item) => _buildOrderItem(context, item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, OrderItemModel item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final imageUrl = item.product?.imagePath ?? '';
    final name = item.product?.name ?? item.productName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.r10),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.fastfood_rounded, color: muted),
                    ),
                  )
                : ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(Icons.fastfood_rounded, color: muted),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.l10n.quantity}: ${item.quantity}',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          Text(
            item.formattedPrice,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderSummaryCard extends StatelessWidget {
  final OrderModel order;

  const OrderSummaryCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: l10n.paymentSummaryTitle),
            const SizedBox(height: 8),
            _buildSummaryRow(context, l10n.paymentSubtotalLabel, order.formattedSubtotal),
            _buildSummaryRow(context, l10n.paymentAndCost, order.formattedDeliveryFee),
            _buildSummaryRow(context, l10n.amount, order.formattedTax),
            if (order.discount > 0)
              _buildSummaryRow(
                context,
                l10n.amount,
                '-${order.formattedDiscount}',
                color: AppColors.successColor,
              ),
            Divider(color: (isDark ? AppColors.mutedDark : AppColors.mutedLight).withOpacity(0.25)),
            _buildSummaryRow(
              context,
              l10n.paymentTotalAmountLabel,
              order.formattedTotal,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool isTotal = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: color ?? (isTotal ? AppColors.primaryColor : null),
            ),
          ),
        ],
      ),
    );
  }
}

class RateOrderCard extends StatefulWidget {
  final OrderModel order;
  final void Function(int rating, String? review) onRate;

  const RateOrderCard({
    Key? key,
    required this.order,
    required this.onRate,
  }) : super(key: key);

  @override
  State<RateOrderCard> createState() => _RateOrderCardState();
}

class _RateOrderCardState extends State<RateOrderCard> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: context.l10n.orderStatusTextDelivered),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    _rating >= starValue ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.ratingFilled,
                    size: 36,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _rating = starValue),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: context.l10n.addReviewOptional,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppColors.r10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 3,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || _rating == 0
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        widget.onRate(
                          _rating,
                          _reviewController.text.trim().isEmpty
                              ? null
                              : _reviewController.text.trim(),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.lightOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.r10),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.lightOnPrimary,
                        ),
                      )
                    : Text(context.l10n.actionSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CancelOrderDialog extends StatefulWidget {
  final OrderModel order;
  final Function(String?) onCancel;

  const CancelOrderDialog({
    Key? key,
    required this.order,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.r16),
      ),
      title: Text(l10n.handymanDialogCancelRequestTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.handymanDialogCancelRequestMessage,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.orderAppBarTitle(widget.order.orderNumber),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: l10n.addReviewOptional,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.r10),
              ),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim();
            widget.onCancel(reason);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text(l10n.actionYesCancel),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
