import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';

class ChatConversationsListResult {
  final List<ChatConversationModel> conversations;
  final int totalUnread;

  const ChatConversationsListResult({
    required this.conversations,
    this.totalUnread = 0,
  });

  factory ChatConversationsListResult.fromResponse(
    dynamic data, {
    Map<String, dynamic>? meta,
  }) {
    final list = <ChatConversationModel>[];
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          list.add(ChatConversationModel.fromJson(item));
        } else if (item is Map) {
          list.add(
            ChatConversationModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final totalUnread = meta?['total_unread'] is int
        ? meta!['total_unread'] as int
        : int.tryParse(meta?['total_unread']?.toString() ?? '') ?? 0;
    return ChatConversationsListResult(
      conversations: list,
      totalUnread: totalUnread,
    );
  }
}
