part of 'chat_room_bloc.dart';

abstract class ChatRoomState {
  const ChatRoomState();
}

class ChatRoomInitial extends ChatRoomState {
  const ChatRoomInitial();
}

class ChatRoomLoading extends ChatRoomState {
  const ChatRoomLoading();
}

class ChatRoomLoaded extends ChatRoomState {
  final ChatConversationModel conversation;
  final List<ChatMessageModel> messages;
  final List<ChatParticipantModel> participants;
  final bool isSending;
  final int? editingMessageId;
  final String? editingDraft;
  final int newMessagesWhileScrolledUp;

  const ChatRoomLoaded({
    required this.conversation,
    required this.messages,
    required this.participants,
    this.isSending = false,
    this.editingMessageId,
    this.editingDraft,
    this.newMessagesWhileScrolledUp = 0,
  });

  ChatRoomLoaded copyWith({
    ChatConversationModel? conversation,
    List<ChatMessageModel>? messages,
    List<ChatParticipantModel>? participants,
    bool? isSending,
    int? editingMessageId,
    String? editingDraft,
    int? newMessagesWhileScrolledUp,
    bool clearEditing = false,
  }) {
    return ChatRoomLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      participants: participants ?? this.participants,
      isSending: isSending ?? this.isSending,
      editingMessageId:
          clearEditing ? null : (editingMessageId ?? this.editingMessageId),
      editingDraft: clearEditing ? null : (editingDraft ?? this.editingDraft),
      newMessagesWhileScrolledUp:
          newMessagesWhileScrolledUp ?? this.newMessagesWhileScrolledUp,
    );
  }
}

class ChatRoomFailure extends ChatRoomState {
  final String message;

  const ChatRoomFailure(this.message);
}
