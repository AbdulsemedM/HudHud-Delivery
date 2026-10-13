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

/// Thin brand ring around an avatar.
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
        border: Border.all(color: HomeColors.violetOf(context), width: 2),
      ),
      child: child,
    );
  }
}

/// Page header for the "My deliveries" tab: big title + the user's avatar.
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
      children: [
        const Expanded(child: OrdersTitle()),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: HomeColors.surfaceOf(context),
            border: Border.all(color: HomeColors.borderOf(context)),
            boxShadow: AppColors.softShadow(context),
          ),
          child: UserAvatar(
            radius: 22,
            imageUrl: getDisplayAvatarUrl(user),
            name: user?.name,
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
      l10n.navMyDeliveries,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: HomeColors.textPrimaryOf(context),
      ),
    );
  }
}

IconData _iconForStatus(String? status) {
  switch (status?.toLowerCase()) {
    case null:
      return Icons.receipt_long_rounded;
    case 'pending':
      return Icons.schedule_rounded;
    case 'confirmed':
    case 'accepted':
      return Icons.thumb_up_alt_rounded;
    case 'preparing':
      return Icons.restaurant_rounded;
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

/// Horizontally scrolling status filters. Pads itself by 16 on both ends so
/// it should be placed edge-to-edge (no outer horizontal padding).
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
    final entries = filters.entries.toList();

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final entry = entries[i];
          return _FilterPill(
            label: entry.value,
            icon: _iconForStatus(entry.key),
            accent: entry.key == null
                ? HomeColors.violetOf(context)
                : StatusChip.colorForStatus(entry.key!),
            selected: selectedStatus == entry.key,
            onTap: () => onFilterChanged(entry.key),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final indigo = HomeColors.violetOf(context);
    final radius = BorderRadius.circular(AppColors.radiusFull);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? indigo : HomeColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? indigo : HomeColors.borderOf(context),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : accent,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : HomeColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card-shaped skeleton list shown while orders load.
class OrdersShimmer extends StatelessWidget {
  const OrdersShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final baseColor = HomeColors.surfaceElevatedOf(context);
    final highlightColor = HomeColors.surfaceOf(context);
    final radius = BorderRadius.circular(20);

    Widget bar(double? w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return Column(
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HomeColors.surfaceOf(context),
              borderRadius: radius,
              border:
                  dark ? Border.all(color: HomeColors.borderOf(context)) : null,
              boxShadow: AppColors.softShadow(context),
            ),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: bar(null, 14)),
                            const SizedBox(width: 24),
                            bar(64, 14),
                          ],
                        ),
                        const SizedBox(height: 8),
                        bar(120, 11),
                        const SizedBox(height: 12),
                        bar(84, 22),
                      ],
                    ),
                  ),
                ],
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
    final dark = HomeColors.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: dark ? Border.all(color: HomeColors.borderOf(context)) : null,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: HomeColors.violetTintOf(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: HomeColors.violetOf(context),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$distance KMs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateTime,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textMutedOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shortens very long order numbers for display only
/// ("ORD-20260911-178271364534126335066" -> "#…26335066").
String shortOrderNumber(String orderNumber) {
  final raw = orderNumber.trim();
  if (raw.isEmpty) return '';
  final last = raw.split('-').last;
  if (last.length > 8) return '#…${last.substring(last.length - 8)}';
  return '#$last';
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
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(20);
    final amount =
        'ETB ${double.tryParse(order.totalAmount)?.toStringAsFixed(2) ?? order.totalAmount}';
    final ink = HomeColors.textPrimaryOf(context);
    final muted = HomeColors.textMutedOf(context);

    return Semantics(
      button: true,
      label: '${order.vendor.name}. $amount',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppColors.softShadow(context),
        ),
        child: Material(
          color: HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: dark
                ? BorderSide(color: HomeColors.borderOf(context))
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: dark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _iconForStatus(order.status),
                      color: statusColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.vendor.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              amount,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatDate(order.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            StatusChip(status: order.status),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                shortOrderNumber(order.orderNumber),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: muted.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, color: muted, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
