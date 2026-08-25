import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_conversations_response_parser.dart';

void main() {
  test('parses flat paginated data array', () {
    final result = ChatConversationsResponseParser.parse({
      'success': true,
      'data': {
        'data': [
          {'id': 1, 'type': 'order', 'status': 'active'},
          {'id': 2, 'type': 'support', 'status': 'active'},
        ],
        'meta': {'total_unread': 3},
      },
    });

    expect(result.conversations.length, 2);
    expect(result.totalUnread, 3);
    expect(result.conversations[0].type, ChatConversationType.order);
    expect(result.conversations[1].type, ChatConversationType.support);
  });

  test('merges conversations grouped by type', () {
    final result = ChatConversationsResponseParser.parse({
      'success': true,
      'data': {
        'support': [
          {'id': 10, 'type': 'support', 'status': 'active'},
        ],
        'order': [
          {'id': 20, 'type': 'order', 'status': 'active'},
        ],
        'ride': [
          {'id': 30, 'type': 'ride', 'status': 'active'},
        ],
        'meta': {'total_unread': 1},
      },
    });

    expect(result.conversations.length, 3);
    expect(
      result.conversations.map((c) => c.type).toSet(),
      {
        ChatConversationType.support,
        ChatConversationType.order,
        ChatConversationType.ride,
      },
    );
  });

  test('parses top-level list payload', () {
    final maps = ChatConversationsResponseParser.collectConversationMaps([
      {'id': 5, 'type': 'delivery', 'status': 'active'},
      {'id': 6, 'type': 'taxi', 'status': 'active'},
    ]);

    expect(maps.length, 2);
    final parsed = maps.map(ChatConversationModel.fromJson).toList();
    expect(parsed[0].type, ChatConversationType.order);
    expect(parsed[1].type, ChatConversationType.ride);
  });
}
