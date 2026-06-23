import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_participant_model.dart';

enum ChatConversationType { order, support, ride, packageDelivery, unknown }

class ChatConversationModel {
  final int id;
  final String? publicConversationId;
  final ChatConversationType type;
  final String status;
  final Map<String, dynamic> metadata;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final int unreadCount;
  final ChatMessageModel? lastMessage;
  final List<ChatParticipantModel> participants;
  final String? conversationableType;
  final int? conversationableId;

  const ChatConversationModel({
    required this.id,
    this.publicConversationId,
    required this.type,
    required this.status,
    this.metadata = const {},
    this.lastMessageAt,
    this.createdAt,
    this.unreadCount = 0,
    this.lastMessage,
    this.participants = const [],
    this.conversationableType,
    this.conversationableId,
  });

  String displayTitle({int? currentUserId}) {
    switch (type) {
      case ChatConversationType.order:
        final orderNo = metadata['order_number']?.toString();
        if (orderNo != null && orderNo.isNotEmpty) return orderNo;
        return 'Order #$conversationableId';
      case ChatConversationType.support:
        final subject = metadata['subject']?.toString();
        if (subject != null && subject.isNotEmpty) return subject;
        return 'Support';
      case ChatConversationType.ride:
        final pickup = metadata['pickup_location']?.toString();
        if (pickup != null && pickup.isNotEmpty) {
          return pickup.length > 40 ? '${pickup.substring(0, 40)}…' : pickup;
        }
        return 'Ride #$conversationableId';
      case ChatConversationType.packageDelivery:
        final tracking = metadata['tracking_number']?.toString();
        if (tracking != null && tracking.isNotEmpty) return tracking;
        return 'Package #$conversationableId';
      case ChatConversationType.unknown:
        return counterpartyName(currentUserId) ?? 'Chat';
    }
  }

  String? counterpartyName(int? currentUserId) {
    for (final p in participants) {
      if (currentUserId != null && p.id == currentUserId) continue;
      final role = p.role?.toLowerCase();
      if (role == 'customer' || role == 'passenger') continue;
      return p.name;
    }
    for (final p in participants) {
      if (currentUserId != null && p.id == currentUserId) continue;
      return p.name;
    }
    return participants.isNotEmpty ? participants.first.name : null;
  }

  String? counterpartyAvatar(int? currentUserId) {
    for (final p in participants) {
      if (currentUserId != null && p.id == currentUserId) continue;
      final role = p.role?.toLowerCase();
      if (role == 'customer' || role == 'passenger') continue;
      return p.avatarUrl;
    }
    for (final p in participants) {
      if (currentUserId != null && p.id == currentUserId) continue;
      return p.avatarUrl;
    }
    return participants.isNotEmpty ? participants.first.avatarUrl : null;
  }

  String subtitleLine() {
    switch (type) {
      case ChatConversationType.order:
        final service = metadata['service_type']?.toString();
        final amount = metadata['total_amount']?.toString();
        final parts = <String>[];
        if (service != null && service.isNotEmpty) parts.add(service);
        if (amount != null && amount.isNotEmpty) parts.add(amount);
        return parts.join(' · ');
      case ChatConversationType.support:
        return metadata['user_email']?.toString() ?? '';
      case ChatConversationType.ride:
        final drop = metadata['dropoff_location']?.toString();
        if (drop != null && drop.isNotEmpty) return drop;
        return '';
      case ChatConversationType.packageDelivery:
        final pickup = metadata['pickup_location']?.toString();
        final drop = metadata['dropoff_location']?.toString();
        final parts = <String>[];
        if (pickup != null && pickup.isNotEmpty) parts.add(pickup);
        if (drop != null && drop.isNotEmpty) parts.add(drop);
        return parts.join(' → ');
      case ChatConversationType.unknown:
        return '';
    }
  }

  String lastPreviewText() {
    if (lastMessage == null) return '';
    final msg = lastMessage!;
    if (msg.isDeleted) return '';
    switch (msg.type) {
      case ChatMessageType.image:
        return msg.body.isNotEmpty ? msg.body : '📷 Photo';
      case ChatMessageType.file:
        return msg.body.isNotEmpty ? msg.body : '📎 File';
      case ChatMessageType.audio:
        return msg.body.isNotEmpty ? msg.body : '🎤 Voice message';
      case ChatMessageType.location:
        return msg.body.isNotEmpty ? msg.body : '📍 Location';
      default:
        return msg.body;
    }
  }

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final participantsRaw = json['participants'];
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

    ChatMessageModel? lastMessage;
    final lastRaw = json['last_message'];
    if (lastRaw is Map<String, dynamic>) {
      lastMessage = ChatMessageModel.fromJson(lastRaw);
    } else if (lastRaw is Map) {
      lastMessage = ChatMessageModel.fromJson(Map<String, dynamic>.from(lastRaw));
    }

    final metaRaw = json['metadata'];
    Map<String, dynamic> metadata = {};
    if (metaRaw is Map<String, dynamic>) {
      metadata = metaRaw;
    } else if (metaRaw is Map) {
      metadata = Map<String, dynamic>.from(metaRaw);
    }

    return ChatConversationModel(
      id: _asInt(json['id']) ?? 0,
      publicConversationId: json['conversation_id']?.toString(),
      type: _parseType(json['type']?.toString()),
      status: json['status']?.toString() ?? 'active',
      metadata: metadata,
      lastMessageAt: _parseDate(json['last_message_at']),
      createdAt: _parseDate(json['created_at']),
      unreadCount: _asInt(json['unread_count']) ?? 0,
      lastMessage: lastMessage,
      participants: participants,
      conversationableType: json['conversationable_type']?.toString(),
      conversationableId: _asInt(json['conversationable_id']),
    );
  }

  static ChatConversationType _parseType(String? type) {
    final normalized = type?.toLowerCase().trim();
    switch (normalized) {
      case 'order':
      case 'orders':
      case 'customer_order':
      case 'delivery':
        return ChatConversationType.order;
      case 'support':
        return ChatConversationType.support;
      case 'ride':
      case 'rides':
      case 'taxi':
        return ChatConversationType.ride;
      case 'package_delivery':
      case 'package-delivery':
        return ChatConversationType.packageDelivery;
      default:
        return ChatConversationType.unknown;
    }
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}
