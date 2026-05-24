import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_avatar.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_unread_badge.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_format_utils.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class ConversationListTile extends StatelessWidget {
  final ChatConversationModel conversation;
  final int? currentUserId;
  final VoidCallback onTap;

  const ConversationListTile({
    super.key,
    required this.conversation,
    this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = conversation.counterpartyName(currentUserId) ??
        conversation.displayTitle(currentUserId: currentUserId);
    final preview = conversation.lastPreviewText();
    final time = ChatFormatUtils.formatListTime(
      conversation.lastMessageAt ?? conversation.createdAt,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ChatAvatar(
                imageUrl: conversation.counterpartyAvatar(currentUserId),
                name: title,
                size: 56,
                showUnreadRing: conversation.unreadCount > 0,
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
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _TypeChip(
                          label: _typeLabel(l10n, conversation.type),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            preview.isEmpty
                                ? conversation.subtitleLine()
                                : preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        ChatUnreadBadge(count: conversation.unreadCount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n, ChatConversationType type) {
    switch (type) {
      case ChatConversationType.order:
        return l10n.chatTypeOrder;
      case ChatConversationType.support:
        return l10n.chatTypeSupport;
      case ChatConversationType.ride:
        return l10n.chatTypeRide;
      case ChatConversationType.unknown:
        return '';
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
