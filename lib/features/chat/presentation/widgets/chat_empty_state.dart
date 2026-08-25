import 'package:flutter/material.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class ChatEmptyState extends StatelessWidget {
  final VoidCallback? onContactSupport;
  final VoidCallback? onViewOrders;

  const ChatEmptyState({
    super.key,
    this.onContactSupport,
    this.onViewOrders,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.chatEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.chatEmptySubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            if (onContactSupport != null)
              FilledButton.icon(
                onPressed: onContactSupport,
                icon: const Icon(Icons.support_agent_rounded),
                label: Text(l10n.chatContactSupport),
              ),
            if (onViewOrders != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onViewOrders,
                child: Text(l10n.chatViewOrders),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
