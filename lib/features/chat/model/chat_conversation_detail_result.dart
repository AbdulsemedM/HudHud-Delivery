import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_open_conversation_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_participant_model.dart';

class ChatConversationDetailResult {
  final ChatConversationModel conversation;
  final List<ChatMessageModel> messages;
  final List<ChatParticipantModel> participants;

  const ChatConversationDetailResult({
    required this.conversation,
    required this.messages,
    this.participants = const [],
  });

  /// Builds room state from POST open/create responses (e.g. support chat)
  /// so the UI can open before GET /conversations/{id} is available.
  factory ChatConversationDetailResult.fromOpenResult(
    ChatOpenConversationResult open,
  ) {
    final conversation = open.conversation ??
        ChatConversationModel(
          id: open.conversationId,
          type: ChatConversationType.support,
          status: 'active',
        );
    return ChatConversationDetailResult(
      conversation: conversation,
      messages: const [],
      participants: conversation.participants,
    );
  }

  factory ChatConversationDetailResult.fromResponseData(
    Map<String, dynamic> data,
  ) {
    final conversationRaw = data['conversation'];
    ChatConversationModel conversation;
    if (conversationRaw is Map<String, dynamic>) {
      conversation = ChatConversationModel.fromJson(conversationRaw);
    } else if (conversationRaw is Map) {
      conversation = ChatConversationModel.fromJson(
        Map<String, dynamic>.from(conversationRaw),
      );
    } else {
      throw Exception('Invalid conversation response');
    }

    final messagesRaw = data['messages'] ??
        (conversationRaw is Map ? conversationRaw['messages'] : null);
    final messages = _parseMessages(messagesRaw);

    final participantsRaw = data['participants'];
    final participants = <ChatParticipantModel>[];
    if (participantsRaw is List) {
      for (final p in participantsRaw) {
        if (p is Map<String, dynamic>) {
          participants.add(ChatParticipantModel.fromJson(p));
        } else if (p is Map) {
          participants.add(
            ChatParticipantModel.fromJson(Map<String, dynamic>.from(p)),
          );
        }
      }
    }

    return ChatConversationDetailResult(
      conversation: conversation,
      messages: messages,
      participants: participants.isNotEmpty
          ? participants
          : conversation.participants,
    );
  }

  static List<ChatMessageModel> _parseMessages(dynamic raw) {
    final list = <ChatMessageModel>[];
    final seenIds = <int>{};
    if (raw is! List) return list;
    for (final item in raw) {
      ChatMessageModel? message;
      if (item is Map<String, dynamic>) {
        message = ChatMessageModel.fromJson(item);
      } else if (item is Map) {
        message = ChatMessageModel.fromJson(Map<String, dynamic>.from(item));
      }
      if (message == null || message.id <= 0) continue;
      if (!seenIds.add(message.id)) continue;
      list.add(message);
    }
    // API returns newest first; UI uses reverse list — keep chronological asc.
    list.sort((a, b) {
      final at = a.createdAt ?? a.deliveredAt ?? DateTime(1970);
      final bt = b.createdAt ?? b.deliveredAt ?? DateTime(1970);
      return at.compareTo(bt);
    });
    return list;
  }
}
