import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_open_conversation_result.dart';

void main() {
  test('fromOpenResult uses conversation from create response', () {
    const open = ChatOpenConversationResult(
      conversationId: 5,
      conversation: ChatConversationModel(
        id: 5,
        type: ChatConversationType.support,
        status: 'active',
        metadata: {'subject': 'Help'},
      ),
    );

    final detail = ChatConversationDetailResult.fromOpenResult(open);

    expect(detail.conversation.id, 5);
    expect(detail.conversation.type, ChatConversationType.support);
    expect(detail.conversation.metadata['subject'], 'Help');
    expect(detail.messages, isEmpty);
  });

  test('fromOpenResult falls back when conversation missing', () {
    const open = ChatOpenConversationResult(conversationId: 7);

    final detail = ChatConversationDetailResult.fromOpenResult(open);

    expect(detail.conversation.id, 7);
    expect(detail.conversation.type, ChatConversationType.support);
    expect(detail.messages, isEmpty);
  });
}
