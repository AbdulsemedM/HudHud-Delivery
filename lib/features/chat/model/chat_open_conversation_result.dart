import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';

class ChatOpenConversationResult {
  final int conversationId;
  final ChatConversationModel? conversation;

  const ChatOpenConversationResult({
    required this.conversationId,
    this.conversation,
  });
}
