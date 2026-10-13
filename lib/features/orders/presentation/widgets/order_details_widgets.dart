import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_tracking_model.dart';
import '../../data/models/vendor_model.dart';

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

/// White rounded card with the app's soft shadow (border in dark mode).
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: dark ? Border.all(color: HomeColors.borderOf(context)) : null,
        boxShadow: AppColors.softShadow(context),
      ),
      child: child,
    );
  }
}

/// Tinted rounded square holding an icon.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 24,
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
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Card title row: icon tile + bold title + optional trailing widget.
class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.title,
    this.color,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconTile(icon: icon, color: color ?? HomeColors.violetOf(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

/// Receipt-style label / value row.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: HomeColors.textMutedOf(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed horizontal rule, like a torn receipt line.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: CustomPaint(
        size: const Size(double.infinity, 1.5),
        painter: _HorizontalDashPainter(color: HomeColors.borderOf(context)),
      ),
    );
  }
}

class _HorizontalDashPainter extends CustomPainter {
  _HorizontalDashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, 0), Offset((x + 6).clamp(0, size.width), 0), paint);
      x += 11;
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalDashPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Circle avatar from a network URL, falling back to the name's initial.
class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({
    required this.url,
    required this.name,
    this.radius = 24,
  });

  final String url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first;
    final fallback = Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HomeColors.violetTintOf(context),
      ),
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w800,
          color: HomeColors.violetOf(context),
        ),
      ),
    );
    if (!url.startsWith('http')) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Round green phone button (keeps the original no-op behaviour).
class _CallButton extends StatelessWidget {
  const _CallButton();

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Material(
      color: AppColors.successColor.withValues(alpha: dark ? 0.2 : 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.call_rounded,
            color: AppColors.successColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}

IconData _statusIcon(String status) {
  switch (status.toLowerCase().replaceAll(' ', '_')) {
    case 'pending':
      return Icons.schedule_rounded;
    case 'confirmed':
    case 'accepted':
      return Icons.thumb_up_alt_rounded;
    case 'preparing':
      return Icons.restaurant_rounded;
    case 'ready_for_pickup':
      return Icons.inventory_2_rounded;
    case 'on_the_way':
    case 'out_for_delivery':
    case 'picked_up':
      return Icons.delivery_dining_rounded;
    case 'delivered':
    case 'completed':
      return Icons.task_alt_rounded;
    case 'cancelled':
    case 'canceled':
      return Icons.cancel_rounded;
    default:
      return Icons.receipt_long_rounded;
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

class OrderStatusCard extends StatelessWidget {
  final OrderModel order;
  final String? trackingEstimatedTime;

  const OrderStatusCard({
    Key? key,
    required this.order,
    this.trackingEstimatedTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final eta = (trackingEstimatedTime != null &&
            trackingEstimatedTime!.trim().isNotEmpty)
        ? trackingEstimatedTime
        : order.formattedEstimatedDelivery;
    final statusColor = StatusChip.colorForStatus(order.status);
    final dark = HomeColors.isDark(context);

    return _DetailCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(
                icon: _statusIcon(order.status),
                color: statusColor,
                size: 56,
                iconSize: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deliveryDetailsStatus,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HomeColors.textMutedOf(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(status: order.statusDisplayName),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: HomeColors.textMutedOf(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.formattedCreatedAt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ],
          ),
          if (eta != null && eta.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    size: 20,
                    color: AppColors.brandOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      eta,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: HomeColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
    final statusColor = StatusChip.colorForStatus(tracking.orderStatus);
    final muted = HomeColors.textMutedOf(context);

    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
              ),
            ],
          ),
        );

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.location_on_rounded,
            title: l10n.actionTrackDelivery,
            color: statusColor,
            trailing: StatusChip(status: tracking.orderStatus),
          ),
          if (tracking.currentLocation != null &&
              tracking.currentLocation!.isNotEmpty)
            line(Icons.place_rounded, tracking.currentLocation!),
          if (tracking.estimatedTime != null &&
              tracking.estimatedTime!.isNotEmpty)
            line(Icons.access_time_rounded, tracking.estimatedTime!),
        ],
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
        icon: Icons.check_circle_rounded,
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
        isActive:
            widget.order.isReadyForPickup && !widget.order.isOutForDelivery,
        icon: Icons.inventory_2_rounded,
      ),
      TimelineStep(
        title: l10n.timelineOutDelivery,
        time: widget.order.outForDeliveryAt != null
            ? widget.order.formattedOutForDeliveryAt
            : null,
        isCompleted: widget.order.isOutForDelivery || widget.order.isDelivered,
        isActive: widget.order.isOutForDelivery && !widget.order.isDelivered,
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

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Icons.route_rounded, title: l10n.timeline),
          const SizedBox(height: 18),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            final nextDone = !isLast && steps[index + 1].isCompleted;
            return _buildTimelineStep(context, step, isLast, nextDone);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context,
    TimelineStep step,
    bool isLast,
    bool nextDone,
  ) {
    final indigo = HomeColors.violetOf(context);
    final muted = HomeColors.textMutedOf(context);
    final Color circleColor;
    final Color iconColor;
    if (step.isActive && step.isCompleted) {
      circleColor = AppColors.brandOrange;
      iconColor = Colors.white;
    } else if (step.isCompleted) {
      circleColor = indigo;
      iconColor = Colors.white;
    } else {
      circleColor = HomeColors.surfaceElevatedOf(context);
      iconColor = muted;
    }

    Widget circle = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
        boxShadow: step.isActive && !HomeColors.isDark(context)
            ? [
                BoxShadow(
                  color: AppColors.brandOrange.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(step.icon, size: 20, color: iconColor),
    );

    if (step.isActive) {
      circle = ScaleTransition(scale: _pulseAnimation, child: circle);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                circle,
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: nextDone
                          ? Container(
                              width: 3,
                              decoration: BoxDecoration(
                                color: indigo,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : CustomPaint(
                              painter: _DashedLinePainter(
                                color: HomeColors.borderOf(context),
                              ),
                              child: const SizedBox(width: 3),
                            ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          step.isCompleted ? FontWeight.w800 : FontWeight.w600,
                      color: step.isCompleted
                          ? HomeColors.textPrimaryOf(context)
                          : muted,
                    ),
                  ),
                  if (step.time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.time!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: muted,
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

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 5.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
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

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.inventory_2_rounded,
            title: l10n.labelPackage,
            color: AppColors.brandOrange,
          ),
          const SizedBox(height: 10),
          _InfoRow(label: l10n.labelType, value: order.vendor.name),
          _InfoRow(label: l10n.labelWeight, value: '$itemCount'),
          if (order.items.isNotEmpty)
            _InfoRow(
              label: l10n.labelDescription,
              value: order.items.first.product?.name ??
                  order.items.first.productName,
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
    final muted = HomeColors.textMutedOf(context);
    return _DetailCard(
      child: Row(
        children: [
          _PersonAvatar(url: vendor.avatar, name: vendor.name, radius: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
                if (vendor.phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 16, color: muted),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          vendor.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const _CallButton(),
        ],
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
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.shopping_bag_rounded,
            title: l10n.orders,
            color: AppColors.brandOrange,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: HomeColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(AppColors.radiusFull),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(items.length, (i) {
            return Column(
              children: [
                if (i > 0)
                  Divider(height: 1, color: HomeColors.borderOf(context)),
                _buildOrderItem(context, items[i]),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, OrderItemModel item) {
    final imageUrl = item.product?.imagePath ?? '';
    final name = item.product?.name ?? item.productName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _itemPlaceholder(context);
                    },
                  )
                : _itemPlaceholder(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: HomeColors.surfaceElevatedOf(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Qty: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.formattedPrice,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemPlaceholder(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Container(
      width: 56,
      height: 56,
      color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
      child: const Icon(
        Icons.fastfood_rounded,
        color: AppColors.brandOrange,
        size: 26,
      ),
    );
  }
}

class DeliveryInfoCard extends StatelessWidget {
  final OrderModel order;

  const DeliveryInfoCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = HomeColors.textMutedOf(context);

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconTile(
                icon: Icons.location_on_rounded,
                color: AppColors.brandOrange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.deliveryDetailsPickup,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: muted,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: muted,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            l10n.deliveryDetailsDropoff,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryAddress,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: HomeColors.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.driver != null) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: HomeColors.borderOf(context)),
            const SizedBox(height: 14),
            Row(
              children: [
                _PersonAvatar(
                  url: order.driver!.avatar,
                  name: order.driver!.name,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.driver!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: HomeColors.textPrimaryOf(context),
                        ),
                      ),
                      Text(
                        order.driver!.phone,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _CallButton(),
              ],
            ),
          ],
        ],
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

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.account_balance_wallet_rounded,
            title: l10n.paymentAndCost,
            color: AppColors.successColor,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              StatusChip(status: order.paymentMethod),
              const Spacer(),
              Text(
                order.formattedTotal,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.labelPaymentStatus,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textMutedOf(context),
                  ),
                ),
              ),
              StatusChip(status: order.paymentStatus),
            ],
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
    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.receipt_long_rounded,
            title: l10n.paymentAndCost,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(context, 'Subtotal', order.formattedSubtotal),
          _buildSummaryRow(context, 'Delivery', order.formattedDeliveryFee),
          _buildSummaryRow(context, 'Tax', order.formattedTax),
          if (order.discount > 0)
            _buildSummaryRow(
              context,
              'Discount',
              '-${order.formattedDiscount}',
              color: AppColors.successColor,
            ),
          const _DashedDivider(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: HomeColors.violetTintOf(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: HomeColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                Text(
                  order.formattedTotal,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: dark
                        ? HomeColors.textPrimaryOf(context)
                        : AppColors.brandInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: HomeColors.textMutedOf(context),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color ?? HomeColors.textPrimaryOf(context),
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
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.star_rounded,
            title: l10n.addReviewOptional,
            color: AppColors.ratingFilled,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                iconSize: 40,
                icon: Icon(
                  _rating >= starValue
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: _rating >= starValue
                      ? AppColors.ratingFilled
                      : HomeColors.textMutedOf(context).withValues(alpha: 0.5),
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
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.actionSave),
            ),
          ),
        ],
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
    final indigo = HomeColors.violetOf(context);
    return AlertDialog(
      backgroundColor: HomeColors.surfaceOf(context),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: const _IconTile(
        icon: Icons.cancel_rounded,
        color: AppColors.errorColor,
        size: 56,
        iconSize: 30,
      ),
      title: Text(
        l10n.orderStatusCancelled,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: HomeColors.textPrimaryOf(context),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.orderAppBarTitle(widget.order.orderNumber),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HomeColors.textMutedOf(context),
              ),
            ),
            const SizedBox(height: 12),
            ..._cancelReasons.map(
              (reason) {
                final selected = _selectedReason == reason;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected
                        ? HomeColors.violetTintOf(context)
                        : HomeColors.surfaceElevatedOf(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selected ? indigo : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => setState(() => _selectedReason = reason),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: HomeColors.textPrimaryOf(context),
                                ),
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: selected
                                  ? indigo
                                  : HomeColors.textMutedOf(context),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 4),
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
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HomeColors.textPrimaryOf(context),
                    side: BorderSide(color: HomeColors.borderOf(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.actionCancel),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _selectedReason != null
                      ? () {
                          final reason = _selectedReason == 'Other'
                              ? _reasonController.text
                              : _selectedReason;
                          widget.onCancel(reason);
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.orderStatusCancelled,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
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
