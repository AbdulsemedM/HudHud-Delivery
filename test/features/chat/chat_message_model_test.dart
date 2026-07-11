import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';

void main() {
  test('MessageModel.fromJson parses text message', () {
    final message = ChatMessageModel.fromJson({
      'id': 1,
      'message_id': 'msg_abc',
      'conversation_id': '1',
      'sender_id': '36',
      'message': 'Hello',
      'type': 'text',
      'attachments': [],
      'is_delivered': true,
      'is_read': false,
      'created_at': '2026-05-20T16:01:21.000000Z',
    });

    expect(message.id, 1);
    expect(message.body, 'Hello');
    expect(message.type, ChatMessageType.text);
    expect(message.isDelivered, isTrue);
    expect(message.isMine(36), isTrue);
    expect(message.isMine(7), isFalse);
  });
}
