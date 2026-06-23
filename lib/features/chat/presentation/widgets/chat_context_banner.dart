import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class ChatContextBanner extends StatelessWidget {
  final ChatConversationModel conversation;
  final VoidCallback? onTap;

  const ChatContextBanner({
    super.key,
    required this.conversation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation.type != ChatConversationType.order &&
        conversation.type != ChatConversationType.ride &&
        conversation.type != ChatConversationType.packageDelivery) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final meta = conversation.metadata;
    final theme = Theme.of(context);

    String title;
    String subtitle;
    IconData icon;
    if (conversation.type == ChatConversationType.order) {
      icon = Icons.receipt_long_rounded;
      title = meta['order_number']?.toString() ?? l10n.chatTypeOrder;
      final amount = meta['total_amount']?.toString();
      final service = meta['service_type']?.toString();
      subtitle = [service, amount].where((e) => e != null && e.isNotEmpty).join(' · ');
    } else if (conversation.type == ChatConversationType.packageDelivery) {
      icon = Icons.local_shipping_outlined;
      title = meta['tracking_number']?.toString() ?? 'Package delivery';
      final status = meta['delivery_status_label']?.toString() ??
          meta['delivery_status']?.toString();
      final route = [
        meta['pickup_location'],
        meta['dropoff_location'],
      ].whereType<String>().where((s) => s.isNotEmpty).join(' → ');
      subtitle = [status, route]
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .join(' · ');
    } else {
      icon = Icons.local_taxi_rounded;
      title = l10n.chatTypeRide;
      subtitle = [
        meta['pickup_location'],
        meta['dropoff_location'],
      ].whereType<String>().where((s) => s.isNotEmpty).join(' → ');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Text(
                    l10n.chatOpenOrder,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
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
