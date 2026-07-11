import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_avatar.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_unread_badge.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_format_utils.dart';

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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;
    final title = conversation.counterpartyName(currentUserId) ??
        conversation.displayTitle(currentUserId: currentUserId);
    final preview = conversation.lastPreviewText();
    final time = ChatFormatUtils.formatListTime(
      conversation.lastMessageAt ?? conversation.createdAt,
    );

    return Material(
      color: hasUnread
          ? AppColors.primaryColor.withValues(alpha: 0.04)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ChatAvatar(
                    imageUrl: conversation.counterpartyAvatar(currentUserId),
                    name: title,
                    size: 56,
                    showUnreadRing: false,
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
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
                              fontWeight:
                                  hasUnread ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        Text(
                          time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: hasUnread
                                ? AppColors.primaryColor
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _TypeChip(
                          label: _typeLabel(l10n, conversation.type),
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            preview.isEmpty
                                ? conversation.subtitleLine()
                                : preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread)
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

  String _typeLabel(dynamic l10n, ChatConversationType type) {
    switch (type) {
      case ChatConversationType.order:
        return l10n.chatTypeOrder;
      case ChatConversationType.support:
        return l10n.chatTypeSupport;
      case ChatConversationType.ride:
        return l10n.chatTypeRide;
      case ChatConversationType.packageDelivery:
        return 'Delivery';
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.rFull),
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
