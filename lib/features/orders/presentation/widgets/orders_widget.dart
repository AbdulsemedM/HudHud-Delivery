import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/core/widgets/section_header.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/core/widgets/user_avatar.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/order_model.dart';

String localizedOrderStatus(BuildContext context, String status) {
  final l10n = context.l10n;
  switch (status.toLowerCase()) {
    case 'pending':
      return l10n.orderStatusPending;
    case 'confirmed':
    case 'accepted':
      return l10n.orderStatusConfirmed;
    case 'preparing':
      return l10n.orderStatusPreparing;
    case 'on_the_way':
    case 'out_for_delivery':
    case 'picked_up':
      return l10n.orderStatusOutForDelivery;
    case 'delivered':
      return l10n.orderStatusDelivered;
    case 'cancelled':
      return l10n.orderStatusCancelled;
    default:
      return status;
  }
}

Color orderStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return AppColors.pending;
    case 'confirmed':
    case 'accepted':
      return AppColors.confirmed;
    case 'preparing':
      return AppColors.preparing;
    case 'on_the_way':
    case 'out_for_delivery':
    case 'picked_up':
      return AppColors.onTheWay;
    case 'delivered':
      return AppColors.delivered;
    case 'cancelled':
      return AppColors.cancelled;
    default:
      return AppColors.mutedLight;
  }
}

IconData orderStatusIcon(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('pending')) return Icons.schedule_rounded;
  if (normalized.contains('confirm') || normalized.contains('accept')) {
    return Icons.check_circle_outline_rounded;
  }
  if (normalized.contains('prepar')) return Icons.restaurant_rounded;
  if (normalized.contains('way') ||
      normalized.contains('delivery') ||
      normalized.contains('pick')) {
    return Icons.local_shipping_outlined;
  }
  if (normalized.contains('deliver')) return Icons.check_circle_rounded;
  if (normalized.contains('cancel')) return Icons.cancel_outlined;
  return Icons.receipt_long_outlined;
}

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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryLightColor,
            AppColors.secondaryColor,
          ],
        ),
      ),
      child: child,
    );
  }
}

class OrdersHeader extends StatelessWidget {
  final String? avatarUrl;

  const OrdersHeader({
    super.key,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StoryRing(
          child: UserAvatar(
            radius: 20,
            imageUrl: avatarUrl,
            backgroundColor: colorScheme.surface,
            iconColor: colorScheme.onSurface.withOpacity(0.45),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: colorScheme.onSurface,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}

class OrdersTitle extends StatelessWidget {
  const OrdersTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: context.l10n.navOrderHistory,
    );
  }
}

class OrderStatusFilterChips extends StatelessWidget {
  const OrderStatusFilterChips({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filters = <({String? value, String label})>[
      (value: null, label: l10n.tipsStatusAll),
      (value: 'pending', label: l10n.orderStatusPending),
      (value: 'confirmed', label: l10n.orderStatusConfirmed),
      (value: 'on_the_way', label: l10n.orderStatusOutForDelivery),
      (value: 'delivered', label: l10n.orderStatusDelivered),
      (value: 'cancelled', label: l10n.orderStatusCancelled),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedStatus == filter.value;

          return FilterChip(
            label: Text(filter.label),
            selected: isSelected,
            showCheckmark: false,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryColor
                  : theme.colorScheme.onSurface,
            ),
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            selectedColor: AppColors.primaryColor.withOpacity(0.12),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryColor.withOpacity(0.5)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.rFull),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onSelected: (_) => onStatusChanged(filter.value),
          );
        },
      ),
    );
  }
}

class OrdersListShimmer extends StatelessWidget {
  const OrdersListShimmer({super.key});

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
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: placeholder,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: placeholder,
                    borderRadius: BorderRadius.circular(AppColors.r10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: placeholder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: placeholder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 24,
                  width: 72,
                  decoration: BoxDecoration(
                    color: placeholder,
                    borderRadius: BorderRadius.circular(AppColors.rFull),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrdersEmptyState extends StatelessWidget {
  const OrdersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.orderHistoryEmptyTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.orderHistoryEmptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersErrorState extends StatelessWidget {
  const OrdersErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: colorScheme.error.withOpacity(0.75),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadOrders(message),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.lightOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.r10),
                ),
              ),
              child: Text(l10n.actionRetry),
            ),
          ],
        ),
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

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    }
    return DateFormat('MMM dd').format(dateTime);
  }

  String _formatAmount() {
    final parsed = double.tryParse(order.totalAmount);
    if (parsed == null) return order.totalAmount;
    return parsed.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final status = localizedOrderStatus(context, order.status);
    final statusColor = orderStatusColor(order.status);
    final statusIcon = orderStatusIcon(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBox(icon: statusIcon, color: statusColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.orderAppBarTitle(order.orderNumber),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(order.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppColors.r10),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: order.vendor.logo != null
                          ? Image.network(
                              order.vendor.logo!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => ColoredBox(
                                color: statusColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.store_rounded,
                                  color: statusColor,
                                ),
                              ),
                            )
                          : ColoredBox(
                              color: statusColor.withOpacity(0.1),
                              child: Icon(
                                Icons.store_rounded,
                                color: statusColor,
                              ),
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.items.length} ${l10n.quantity.toLowerCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.taxiFareAmount(_formatAmount()),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              if (order.deliveryAddress.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
