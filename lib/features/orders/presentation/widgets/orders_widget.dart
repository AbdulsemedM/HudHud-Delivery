import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import '../../data/models/order_model.dart';
import 'package:intl/intl.dart';

class StoryRing extends StatelessWidget {
  const StoryRing({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryColor, width: 2),
      ),
      child: child,
    );
  }
}

class OrdersHeader extends StatelessWidget {
  final VoidCallback? onFilterTap;

  const OrdersHeader({
    super.key,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const StoryRing(
          child: CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/images/profile.png'),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class OrdersTitle extends StatelessWidget {
  const OrdersTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Text(
      l10n.orders,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class OrderFilterChips extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onFilterChanged;

  const OrderFilterChips({
    super.key,
    required this.selectedStatus,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filters = <String?, String>{
      null: l10n.orders,
      'pending': l10n.orderStatusPending,
      'confirmed': l10n.orderStatusConfirmed,
      'on_the_way': l10n.orderStatusOutForDelivery,
      'delivered': l10n.orderStatusDelivered,
      'cancelled': l10n.orderStatusCancelled,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final selected = selectedStatus == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onFilterChanged(entry.key),
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: AppColors.primaryColor,
              side: BorderSide(
                color: selected
                    ? AppColors.primaryColor
                    : Theme.of(context).colorScheme.outline.withOpacity(0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusFull),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class OrdersShimmer extends StatelessWidget {
  const OrdersShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Column(
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class OrderItem extends StatelessWidget {
  final String distance;
  final String amount;
  final String dateTime;

  const OrderItem({
    super.key,
    required this.distance,
    required this.amount,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Text(
            '$distance KMs',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateTime,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderItemCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderItemCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'preparing':
        return Icons.restaurant_rounded;
      case 'on_the_way':
        return Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return DateFormat('MMM dd').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = StatusChip.colorForStatus(order.status);
    final amount =
        'ETB ${double.tryParse(order.totalAmount)?.toStringAsFixed(2) ?? order.totalAmount}';

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusLG),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(order.status),
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.orderNumber}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.vendor.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(order.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(status: order.status),
                  const SizedBox(height: 8),
                  Text(
                    amount,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
