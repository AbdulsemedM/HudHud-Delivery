import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/orders/data/models/order_model.dart';
import 'package:hudhud_delivery/features/orders/presentation/widgets/orders_widget.dart'
    show localizedOrderStatus;
import 'package:hudhud_delivery/features/sos/presentation/widgets/sos_trigger_button.dart';
import 'package:share_plus/share_plus.dart';

/// App bar for [OrderDetailsScreen] showing order number and actions.
class OrderDetailsSliverHeader extends StatelessWidget {
  const OrderDetailsSliverHeader({
    super.key,
    required this.order,
    required this.onChat,
    this.onCancel,
  });

  final OrderModel order;
  final VoidCallback onChat;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        l10n.orderAppBarTitle(order.orderNumber),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          tooltip: l10n.chatOrderTitle,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          onPressed: onChat,
        ),
        SosTriggerButton(compact: true, orderId: order.id),
        _OrderHeaderMenu(order: order, onCancel: onCancel),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _OrderHeaderMenu extends StatelessWidget {
  const _OrderHeaderMenu({
    required this.order,
    this.onCancel,
  });

  final OrderModel order;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.r12),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'copy':
            await Clipboard.setData(ClipboardData(text: '${order.id}'));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.orderIdCopied)),
              );
            }
          case 'share':
            Share.share(
              '${l10n.orderAppBarTitle(order.orderNumber)} (ID: ${order.id})\n${localizedOrderStatus(context, order.status)}',
              subject: l10n.orderShareSubject,
            );
          case 'cancel':
            onCancel?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'copy',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.copy_rounded, size: 22),
            title: Text(l10n.chatCopy),
            subtitle: Text(
              '#${order.id}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.share_rounded, size: 22),
            title: Text(l10n.orderShareSubject),
          ),
        ),
        if (onCancel != null)
          PopupMenuItem(
            value: 'cancel',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.cancel_outlined,
                size: 22,
                color: scheme.error,
              ),
              title: Text(
                l10n.orderStatusCancelled,
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
