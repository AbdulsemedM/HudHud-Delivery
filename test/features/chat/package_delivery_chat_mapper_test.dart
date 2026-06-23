import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/utils/package_delivery_chat_mapper.dart';

void main() {
  const sampleData = {
    'conversation_id': 15,
    'conversation': {
      'id': 15,
      'conversation_id': 'conv_6a184940d33db_aca993c01c90946c',
      'conversationable_type': r'App\Models\PackageDelivery',
      'conversationable_id': '1',
      'type': 'package_delivery',
      'status': 'active',
      'metadata': {
        'tracking_number': 'PKG202605284F5A7D',
        'pickup_location': '123 Main Street, New York',
        'dropoff_location': '456 Broadway, New York',
        'package_type': 'document',
        'package_weight': '0.50',
        'estimated_cost': '120.00',
        'service_type': 'express',
      },
      'last_message_at': '2026-05-28T14:21:08.000000Z',
      'created_at': '2026-05-28T13:55:12.000000Z',
      'updated_at': '2026-05-28T13:55:12.000000Z',
      'deleted_at': null,
    },
    'messages': [
      {
        'id': 17,
        'message_id': 'msg_6a184f540558c_d99040a1d5c78185',
        'conversation_id': '15',
        'sender_id': '2',
        'message': 'Hello driver, when will you arrive for pickup?',
        'type': 'text',
        'attachments': [],
        'metadata': null,
        'is_read': true,
        'read_at': '2026-05-28T14:24:46.000000Z',
        'is_delivered': true,
        'delivered_at': '2026-05-28T14:21:08.000000Z',
        'is_edited': false,
        'edited_at': null,
        'is_deleted': false,
        'deleted_at': null,
        'created_at': '2026-05-28T14:21:08.000000Z',
        'updated_at': '2026-05-28T14:24:46.000000Z',
        'sender': {
          'id': 2,
          'name': 'Customer 1',
        },
      },
    ],
    'participants': [],
    'delivery_info': {
      'id': 1,
      'tracking_number': 'PKG202605284F5A7D',
      'status': 'pickup_assigned',
      'status_label': 'Driver Assigned',
      'pickup_location': '123 Main Street, New York',
      'dropoff_location': '456 Broadway, New York',
      'package_type': 'Document',
      'package_weight': '0.50',
      'estimated_cost': '\$120.00',
      'driver': {
        'id': 41,
        'name': 'Driver Name',
        'phone': '+1234567890',
        'avatar': null,
      },
    },
  };

  test('parses package delivery conversation detail from API shape', () {
    final detail = ChatConversationDetailResult.fromResponseData(sampleData);

    expect(detail.conversation.id, 15);
    expect(detail.messages, hasLength(1));
    expect(detail.messages.first.body,
        'Hello driver, when will you arrive for pickup?');
    expect(detail.participants, isEmpty);
  });

  test('enrichDetail adds driver participant and delivery metadata', () {
    final base = ChatConversationDetailResult.fromResponseData(sampleData);
    final enriched = PackageDeliveryChatMapper.enrichDetail(base, sampleData);

    expect(enriched.conversation.type, ChatConversationType.packageDelivery);
    expect(enriched.conversation.conversationableId, 1);
    expect(enriched.conversation.metadata['tracking_number'],
        'PKG202605284F5A7D');
    expect(enriched.conversation.metadata['delivery_status_label'],
        'Driver Assigned');
    expect(enriched.participants, hasLength(1));
    expect(enriched.participants.first.name, 'Driver Name');
    expect(enriched.participants.first.role, 'driver');
    expect(
      enriched.conversation.counterpartyName(2),
      'Driver Name',
    );
    expect(
      enriched.conversation.displayTitle(),
      'PKG202605284F5A7D',
    );
    expect(
      enriched.conversation.subtitleLine(),
      contains('123 Main Street'),
    );
  });

  test('package_delivery type is recognized in conversation model', () {
    final conversation = ChatConversationModel.fromJson({
      'id': 15,
      'type': 'package_delivery',
      'status': 'active',
      'metadata': {
        'tracking_number': 'PKG202605284F5A7D',
        'pickup_location': 'Pickup',
        'dropoff_location': 'Dropoff',
      },
      'conversationable_id': 1,
    });

    expect(conversation.type, ChatConversationType.packageDelivery);
    expect(conversation.displayTitle(), 'PKG202605284F5A7D');
    expect(conversation.subtitleLine(), 'Pickup → Dropoff');
  });
}
