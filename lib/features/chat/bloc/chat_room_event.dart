part of 'chat_room_bloc.dart';

abstract class ChatRoomEvent {
  const ChatRoomEvent();
}

class OpenChatRoomEvent extends ChatRoomEvent {
  final int conversationId;
  final ChatConversationDetailResult? initialDetail;

  const OpenChatRoomEvent(
    this.conversationId, {
    this.initialDetail,
  });
}

class PollChatMessagesEvent extends ChatRoomEvent {
  const PollChatMessagesEvent();
}

class SendTextMessageEvent extends ChatRoomEvent {
  final String text;

  const SendTextMessageEvent(this.text);
}

class SendImageMessageEvent extends ChatRoomEvent {
  final String caption;
  final List<String> filePaths;

  const SendImageMessageEvent({
    required this.caption,
    required this.filePaths,
  });
}

class SendFileMessageEvent extends ChatRoomEvent {
  final String caption;
  final List<String> filePaths;

  const SendFileMessageEvent({
    required this.caption,
    required this.filePaths,
  });
}

class SendAudioMessageEvent extends ChatRoomEvent {
  final String caption;
  final String filePath;

  const SendAudioMessageEvent({
    required this.caption,
    required this.filePath,
  });
}

class SendLocationMessageEvent extends ChatRoomEvent {
  final String caption;
  final double latitude;
  final double longitude;
  final String address;

  const SendLocationMessageEvent({
    required this.caption,
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class EditMessageEvent extends ChatRoomEvent {
  final int messageId;
  final String newText;

  const EditMessageEvent({
    required this.messageId,
    required this.newText,
  });
}

class DeleteMessageEvent extends ChatRoomEvent {
  final int messageId;

  const DeleteMessageEvent(this.messageId);
}

class MarkChatReadEvent extends ChatRoomEvent {
  const MarkChatReadEvent();
}

class StartEditMessageEvent extends ChatRoomEvent {
  final int messageId;
  final String currentText;

  const StartEditMessageEvent({
    required this.messageId,
    required this.currentText,
  });
}

class CancelEditMessageEvent extends ChatRoomEvent {
  const CancelEditMessageEvent();
}

class RetrySendMessageEvent extends ChatRoomEvent {
  final int tempMessageId;

  const RetrySendMessageEvent(this.tempMessageId);
}

class PauseChatPollingEvent extends ChatRoomEvent {
  const PauseChatPollingEvent();
}

class ResumeChatPollingEvent extends ChatRoomEvent {
  const ResumeChatPollingEvent();
}
