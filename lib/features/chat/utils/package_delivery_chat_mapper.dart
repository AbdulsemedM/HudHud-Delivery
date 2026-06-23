import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_participant_model.dart';

/// Normalizes package-delivery conversation API payloads for the shared chat UI.
class PackageDeliveryChatMapper {
  PackageDeliveryChatMapper._();

  static ChatConversationDetailResult enrichDetail(
    ChatConversationDetailResult detail,
    Map<String, dynamic> data,
  ) {
    final deliveryInfo = _asMap(data['delivery_info']);
    if (deliveryInfo == null) return detail;

    final metadata = Map<String, dynamic>.from(detail.conversation.metadata);
    metadata['tracking_number'] ??=
        deliveryInfo['tracking_number']?.toString();
    metadata['pickup_location'] ??=
        deliveryInfo['pickup_location']?.toString();
    metadata['dropoff_location'] ??=
        deliveryInfo['dropoff_location']?.toString();
    metadata['delivery_status'] ??= deliveryInfo['status']?.toString();
    metadata['delivery_status_label'] ??=
        deliveryInfo['status_label']?.toString();
    metadata['package_type'] ??= deliveryInfo['package_type']?.toString();
    metadata['package_weight'] ??= deliveryInfo['package_weight']?.toString();
    metadata['estimated_cost'] ??= deliveryInfo['estimated_cost']?.toString();
    metadata['service_type'] ??= deliveryInfo['service_type']?.toString();

    final deliveryId = _asInt(deliveryInfo['id']);
    final driver = _asMap(deliveryInfo['driver']);
    if (driver != null) {
      metadata['driver_name'] = driver['name']?.toString();
      metadata['driver_phone'] = driver['phone']?.toString();
      metadata['driver_avatar'] = driver['avatar']?.toString();
    }

    final participants = List<ChatParticipantModel>.from(detail.participants);
    if (driver != null && participants.isEmpty) {
      participants.add(
        ChatParticipantModel(
          id: _asInt(driver['id']) ?? 0,
          name: driver['name']?.toString() ?? 'Driver',
          avatarUrl: driver['avatar']?.toString(),
          role: 'driver',
        ),
      );
    }

    final conversation = ChatConversationModel(
      id: detail.conversation.id,
      publicConversationId: detail.conversation.publicConversationId,
      type: ChatConversationType.packageDelivery,
      status: detail.conversation.status,
      metadata: metadata,
      lastMessageAt: detail.conversation.lastMessageAt,
      createdAt: detail.conversation.createdAt,
      unreadCount: detail.conversation.unreadCount,
      lastMessage: detail.conversation.lastMessage,
      participants: participants.isNotEmpty
          ? participants
          : detail.conversation.participants,
      conversationableType: detail.conversation.conversationableType,
      conversationableId:
          deliveryId ?? detail.conversation.conversationableId,
    );

    return ChatConversationDetailResult(
      conversation: conversation,
      messages: detail.messages,
      participants: participants.isNotEmpty
          ? participants
          : detail.participants,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
