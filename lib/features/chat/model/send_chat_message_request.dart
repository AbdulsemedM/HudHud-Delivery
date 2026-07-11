import 'dart:io';

import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';

class SendChatMessageRequest {
  final String message;
  final ChatMessageType type;
  final Map<String, dynamic>? metadata;
  final List<File> attachmentFiles;

  const SendChatMessageRequest({
    required this.message,
    required this.type,
    this.metadata,
    this.attachmentFiles = const [],
  });

  bool get hasAttachments => attachmentFiles.isNotEmpty;

  String get apiType {
    switch (type) {
      case ChatMessageType.text:
        return 'text';
      case ChatMessageType.image:
        return 'image';
      case ChatMessageType.file:
        return 'file';
      case ChatMessageType.audio:
        return 'audio';
      case ChatMessageType.location:
        return 'location';
      case ChatMessageType.unknown:
        return 'text';
    }
  }

  Map<String, dynamic> toJsonBody() {
    final map = <String, dynamic>{
      'message': message,
      'type': apiType,
    };
    if (metadata != null && metadata!.isNotEmpty) {
      map['metadata'] = metadata;
    }
    return map;
  }
}
