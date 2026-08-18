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
    expect(detail.hasLeft, isFalse);
  });

  test('fromOpenResult falls back when conversation missing', () {
    const open = ChatOpenConversationResult(conversationId: 7);

    final detail = ChatConversationDetailResult.fromOpenResult(open);

    expect(detail.conversation.id, 7);
    expect(detail.conversation.type, ChatConversationType.support);
    expect(detail.messages, isEmpty);
    expect(detail.hasLeft, isFalse);
  });

  test('keeps API message order even when timestamps are reversed', () {
    final detail = ChatConversationDetailResult.fromResponseData({
      'conversation': {
        'id': 17,
        'type': 'support',
        'status': 'active',
      },
      'messages': [
        {
          'id': 2,
          'message': 'newer first in payload',
          'type': 'text',
          'created_at': '2026-08-17T12:00:00.000000Z',
        },
        {
          'id': 1,
          'message': 'older second in payload',
          'type': 'text',
          'created_at': '2026-08-17T11:00:00.000000Z',
        },
      ],
      'participants': [],
      'has_left': false,
    });

    expect(detail.messages.map((m) => m.id), [2, 1]);
    expect(detail.hasLeft, isFalse);
  });

  test('parses has_left true with empty messages as success', () {
    final detail = ChatConversationDetailResult.fromResponseData({
      'conversation': {
        'id': 17,
        'type': 'support',
        'status': 'active',
      },
      'messages': [],
      'participants': [
        {'id': 3, 'name': 'Support'},
      ],
      'has_left': true,
    });

    expect(detail.hasLeft, isTrue);
    expect(detail.messages, isEmpty);
    expect(detail.participants, isNotEmpty);
  });
}
