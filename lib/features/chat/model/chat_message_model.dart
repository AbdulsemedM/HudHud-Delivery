import 'package:hudhud_delivery/features/chat/model/chat_attachment_model.dart';

enum ChatMessageType {
  text,
  image,
  file,
  audio,
  location,
  unknown,
}

enum ChatMessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessageModel {
  final int id;
  final String? messageId;
  final int conversationId;
  final int senderId;
  final String body;
  final ChatMessageType type;
  final List<ChatAttachmentModel> attachments;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime? readAt;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? senderName;
  final ChatMessageStatus? localStatus;

  const ChatMessageModel({
    required this.id,
    this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.type,
    this.attachments = const [],
    this.metadata,
    this.isRead = false,
    this.readAt,
    this.isDelivered = false,
    this.deliveredAt,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.senderName,
    this.localStatus,
  });

  bool isMine(int? currentUserId) {
    if (currentUserId == null) return false;
    return senderId == currentUserId;
  }

  ChatMessageStatus deliveryStatus({ChatMessageStatus? override}) {
    if (override != null) return override;
    if (localStatus != null) return localStatus!;
    if (isRead) return ChatMessageStatus.read;
    if (isDelivered) return ChatMessageStatus.delivered;
    return ChatMessageStatus.sent;
  }

  ChatMessageModel copyWith({
    int? id,
    String? messageId,
    int? conversationId,
    int? senderId,
    String? body,
    ChatMessageType? type,
    List<ChatAttachmentModel>? attachments,
    Map<String, dynamic>? metadata,
    bool? isRead,
    DateTime? readAt,
    bool? isDelivered,
    DateTime? deliveredAt,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? senderName,
    ChatMessageStatus? localStatus,
    bool clearLocalStatus = false,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      body: body ?? this.body,
      type: type ?? this.type,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isDelivered: isDelivered ?? this.isDelivered,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderName: senderName ?? this.senderName,
      localStatus:
          clearLocalStatus ? null : (localStatus ?? this.localStatus),
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final attachmentsRaw = json['attachments'];
    final attachments = <ChatAttachmentModel>[];
    if (attachmentsRaw is List) {
      for (final item in attachmentsRaw) {
        if (item is Map<String, dynamic>) {
          attachments.add(ChatAttachmentModel.fromJson(item));
        } else if (item is Map) {
          attachments.add(
            ChatAttachmentModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final sender = json['sender'];
    String? senderName;
    if (sender is Map) {
      senderName = sender['name']?.toString();
    }

    Map<String, dynamic>? metadata;
    final metaRaw = json['metadata'];
    if (metaRaw is Map<String, dynamic>) {
      metadata = metaRaw;
    } else if (metaRaw is Map) {
      metadata = Map<String, dynamic>.from(metaRaw);
    }

    return ChatMessageModel(
      id: _asInt(json['id']) ?? 0,
      messageId: json['message_id']?.toString(),
      conversationId: _asInt(json['conversation_id']) ?? 0,
      senderId: _asInt(json['sender_id']) ?? 0,
      body: json['message']?.toString() ?? '',
      type: _parseType(json['type']?.toString()),
      attachments: attachments,
      metadata: metadata,
      isRead: json['is_read'] == true,
      readAt: _parseDate(json['read_at']),
      isDelivered: json['is_delivered'] == true,
      deliveredAt: _parseDate(json['delivered_at']),
      isEdited: json['is_edited'] == true,
      editedAt: _parseDate(json['edited_at']),
      isDeleted: json['is_deleted'] == true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      senderName: senderName,
    );
  }

  static ChatMessageType _parseType(String? type) {
    switch (type) {
      case 'text':
        return ChatMessageType.text;
      case 'image':
        return ChatMessageType.image;
      case 'file':
        return ChatMessageType.file;
      case 'audio':
        return ChatMessageType.audio;
      case 'location':
        return ChatMessageType.location;
      default:
        return ChatMessageType.unknown;
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

  /// Optimistic local message before server assigns id.
  factory ChatMessageModel.optimistic({
    required int tempId,
    required int conversationId,
    required int senderId,
    required String body,
    required ChatMessageType type,
    List<String>? localFilePaths,
  }) {
    return ChatMessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      localStatus: ChatMessageStatus.sending,
      attachments: localFilePaths
              ?.map(
                (p) => ChatAttachmentModel(
                  filePath: p,
                  name: p.split('/').last,
                ),
              )
              .toList() ??
          const [],
    );
  }
}
