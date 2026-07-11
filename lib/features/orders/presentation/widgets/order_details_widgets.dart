import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_tracking_model.dart';
import '../../data/models/vendor_model.dart';

class OrderStatusCard extends StatelessWidget {
  final OrderModel order;

  const OrderStatusCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.deliveryDetailsStatus,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                StatusChip(status: order.statusDisplayName),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.formattedCreatedAt,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (order.estimatedDeliveryTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.formattedEstimatedDelivery,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OrderTrackingCard extends StatelessWidget {
  final OrderTrackingModel tracking;

  const OrderTrackingCard({Key? key, required this.tracking}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = StatusChip.colorForStatus(tracking.orderStatus);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: statusColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.actionTrackDelivery,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatusChip(status: tracking.orderStatus),
            if (tracking.currentLocation != null &&
                tracking.currentLocation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined,
                      size: 18, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tracking.currentLocation!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (tracking.estimatedTime != null &&
                tracking.estimatedTime!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 18, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    tracking.estimatedTime!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OrderTimelineCard extends StatefulWidget {
  final OrderModel order;

  const OrderTimelineCard({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderTimelineCard> createState() => _OrderTimelineCardState();
}

class _OrderTimelineCardState extends State<OrderTimelineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<TimelineStep> _getTimelineSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      TimelineStep(
        title: l10n.timelineOrderPlaced,
        time: widget.order.formattedCreatedAt,
        isCompleted: true,
        isActive: false,
        icon: Icons.shopping_cart_rounded,
      ),
      TimelineStep(
        title: l10n.timelineOrderConfirmed,
        time: widget.order.confirmedAt != null
            ? widget.order.formattedConfirmedAt
            : null,
        isCompleted: widget.order.isConfirmed,
        isActive: widget.order.isConfirmed &&
            !widget.order.isPreparing &&
            !widget.order.isDelivered,
        icon: Icons.check_circle_outline_rounded,
      ),
      TimelineStep(
        title: l10n.timelinePreparing,
        time: widget.order.preparingAt != null
            ? widget.order.formattedPreparingAt
            : null,
        isCompleted: widget.order.isPreparing ||
            widget.order.isReadyForPickup ||
            widget.order.isOutForDelivery ||
            widget.order.isDelivered,
        isActive: widget.order.isPreparing && !widget.order.isOutForDelivery,
        icon: Icons.restaurant_rounded,
      ),
      TimelineStep(
        title: l10n.timelineReadyPickup,
        time: widget.order.readyForPickupAt != null
            ? widget.order.formattedReadyForPickupAt
            : null,
        isCompleted: widget.order.isReadyForPickup ||
            widget.order.isOutForDelivery ||
            widget.order.isDelivered,
        isActive: widget.order.isReadyForPickup &&
            !widget.order.isOutForDelivery,
        icon: Icons.inventory_2_outlined,
      ),
      TimelineStep(
        title: l10n.timelineOutDelivery,
        time: widget.order.outForDeliveryAt != null
            ? widget.order.formattedOutForDeliveryAt
            : null,
        isCompleted:
            widget.order.isOutForDelivery || widget.order.isDelivered,
        isActive:
            widget.order.isOutForDelivery && !widget.order.isDelivered,
        icon: Icons.delivery_dining_rounded,
      ),
      TimelineStep(
        title: l10n.timelineDelivered,
        time: widget.order.deliveredAt != null
            ? widget.order.formattedDeliveredAt
            : null,
        isCompleted: widget.order.isDelivered,
        isActive: widget.order.isDelivered,
        icon: Icons.done_all_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = _getTimelineSteps(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.timeline,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ...List.generate(steps.length, (index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;
              return _buildTimelineStep(context, step, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
      BuildContext context, TimelineStep step, bool isLast) {
    final colorScheme = Theme.of(context).colorScheme;
    final circleColor = step.isCompleted
        ? AppColors.primaryColor
        : colorScheme.surfaceContainerHighest;
    final iconColor =
        step.isCompleted ? Colors.white : colorScheme.onSurfaceVariant;

    Widget circle = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
      ),
      child: Icon(step.icon, size: 16, color: iconColor),
    );

    if (step.isActive) {
      circle = ScaleTransition(scale: _pulseAnimation, child: circle);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              circle,
              if (!isLast)
                Expanded(
                  child: CustomPaint(
                    painter: _DashedLinePainter(
                      color: step.isCompleted
                          ? AppColors.primaryColor.withValues(alpha: 0.5)
                          : colorScheme.outline.withValues(alpha: 0.4),
                    ),
                    child: const SizedBox(width: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: step.isCompleted
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: step.isCompleted
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (step.time != null)
                    Text(
                      step.time!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TimelineStep {
  final String title;
  final String? time;
  final bool isCompleted;
  final bool isActive;
  final IconData icon;

  TimelineStep({
    required this.title,
    this.time,
    required this.isCompleted,
    this.isActive = false,
    required this.icon,
  });
}

class PackageInfoCard extends StatelessWidget {
  final OrderModel order;

  const PackageInfoCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final itemCount = order.items.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.labelPackage,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _infoRow(context, l10n.labelType, order.vendor.name),
            _infoRow(
              context,
              l10n.labelWeight,
              '$itemCount',
            ),
            if (order.items.isNotEmpty)
              _infoRow(
                context,
                l10n.labelDescription,
                order.items.first.product?.name ?? order.items.first.productName,
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

class VendorInfoCard extends StatelessWidget {
  final VendorModel vendor;

  const VendorInfoCard({Key? key, required this.vendor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vendor.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(vendor.avatar),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vendor.phone,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.call_rounded,
                    color: AppColors.successColor,
                  ),
                ),
              ],
            ),
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
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.orders} (${items.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildOrderItem(context, item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, OrderItemModel item) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = item.product?.imagePath ?? '';
    final name = item.product?.name ?? item.productName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _itemPlaceholder(colorScheme);
                    },
                  )
                : _itemPlaceholder(colorScheme),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Text(
            item.formattedPrice,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _itemPlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 50,
      height: 50,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.fastfood_rounded, color: colorScheme.onSurfaceVariant),
    );
  }
}

class DeliveryInfoCard extends StatelessWidget {
  final OrderModel order;

  const DeliveryInfoCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.deliveryDetailsPickup,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Text(
                    l10n.deliveryDetailsDropoff,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (order.driver != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(order.driver!.avatar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.driver!.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          order.driver!.phone,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.call_rounded,
                      color: AppColors.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PaymentInfoCard extends StatelessWidget {
  final OrderModel order;

  const PaymentInfoCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentAndCost,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StatusChip(status: order.paymentMethod),
                const Spacer(),
                Text(
                  order.formattedTotal,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.labelPaymentStatus,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                StatusChip(status: order.paymentStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderSummaryCard extends StatelessWidget {
  final OrderModel order;

  const OrderSummaryCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentAndCost,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(context, 'Subtotal', order.formattedSubtotal),
            _buildSummaryRow(
                context, 'Delivery', order.formattedDeliveryFee),
            _buildSummaryRow(context, 'Tax', order.formattedTax),
            if (order.discount > 0)
              _buildSummaryRow(
                context,
                'Discount',
                '-${order.formattedDiscount}',
                color: AppColors.successColor,
              ),
            const Divider(),
            _buildSummaryRow(
              context,
              'Total',
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                  color: color ??
                      (isTotal ? AppColors.primaryColor : null),
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
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addReviewOptional,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    _rating >= starValue
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.ratingFilled,
                    size: 36,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _rating = starValue),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: l10n.addReviewOptional,
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
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.actionSave),
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
  String? _selectedReason;

  final List<String> _cancelReasons = [
    'Changed my mind',
    'Ordered by mistake',
    'Taking too long',
    'Found better option',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.orderStatusCancelled),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orderAppBarTitle(widget.order.orderNumber),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ..._cancelReasons.map(
            (reason) {
              final selected = _selectedReason == reason;
              return ListTile(
                title: Text(reason),
                contentPadding: EdgeInsets.zero,
                trailing: selected
                    ? const Icon(Icons.check_circle, color: AppColors.primaryColor)
                    : Icon(
                        Icons.circle_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                onTap: () => setState(() => _selectedReason = reason),
              );
            },
          ),
          if (_selectedReason == 'Other') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: l10n.pleaseSpecify,
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: _selectedReason != null
              ? () {
                  final reason = _selectedReason == 'Other'
                      ? _reasonController.text
                      : _selectedReason;
                  widget.onCancel(reason);
                  Navigator.of(context).pop();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorColor,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.orderStatusCancelled),
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
