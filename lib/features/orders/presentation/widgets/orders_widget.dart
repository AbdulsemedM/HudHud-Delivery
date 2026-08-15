import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/avatar_util.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/core/widgets/user_avatar.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/models/user_model.dart';
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
        border: Border.all(color: HomeColors.violet, width: 2),
      ),
      child: child,
    );
  }
}

class OrdersHeader extends StatelessWidget {
  final VoidCallback? onFilterTap;
  final UserModel? user;

  const OrdersHeader({
    super.key,
    this.onFilterTap,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StoryRing(
          child: UserAvatar(
            radius: 20,
            imageUrl: getDisplayAvatarUrl(user),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: HomeColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HomeColors.border),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: HomeColors.textPrimary,
            ),
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
            color: HomeColors.textPrimary,
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
                color: selected ? Colors.white : HomeColors.textMuted,
              ),
              backgroundColor: HomeColors.surface,
              selectedColor: HomeColors.violet,
              side: BorderSide(
                color: selected ? HomeColors.violet : HomeColors.border,
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
    const baseColor = HomeColors.surface;
    const highlightColor = HomeColors.surfaceElevated;

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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: HomeColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: HomeColors.textMuted,
          ),
          const SizedBox(width: 16),
          Text(
            '$distance KMs',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: HomeColors.textPrimary,
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
                  color: HomeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateTime,
                style: const TextStyle(
                  fontSize: 14,
                  color: HomeColors.textMuted,
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
    final statusColor = StatusChip.colorForStatus(order.status);
    final amount =
        'ETB ${double.tryParse(order.totalAmount)?.toStringAsFixed(2) ?? order.totalAmount}';

    return Material(
      color: HomeColors.surface,
      borderRadius: BorderRadius.circular(AppColors.radiusLG),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
            border: Border.all(color: HomeColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: HomeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.vendor.name,
                      style: const TextStyle(
                        color: HomeColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(
                        color: HomeColors.textMuted,
                        fontSize: 12,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: HomeColors.orange,
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
