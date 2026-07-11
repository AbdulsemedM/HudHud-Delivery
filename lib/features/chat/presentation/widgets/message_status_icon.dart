import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';

class MessageStatusIcon extends StatelessWidget {
  final ChatMessageStatus status;
  final bool isMine;
  final Color? onBubbleColor;

  const MessageStatusIcon({
    super.key,
    required this.status,
    required this.isMine,
    this.onBubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMine) return const SizedBox.shrink();

    final color = onBubbleColor ??
        (status == ChatMessageStatus.read
            ? AppColors.secondaryColor
            : Colors.white.withValues(alpha: 0.85));

    switch (status) {
      case ChatMessageStatus.sending:
        return Icon(Icons.schedule_rounded, size: 14, color: color);
      case ChatMessageStatus.failed:
        return Icon(Icons.error_outline_rounded, size: 14, color: Colors.red[300]);
      case ChatMessageStatus.sent:
        return Icon(Icons.check_rounded, size: 14, color: color);
      case ChatMessageStatus.delivered:
        return Icon(Icons.done_all_rounded, size: 14, color: color);
      case ChatMessageStatus.read:
        return Icon(Icons.done_all_rounded, size: 14, color: color);
    }
  }
}
