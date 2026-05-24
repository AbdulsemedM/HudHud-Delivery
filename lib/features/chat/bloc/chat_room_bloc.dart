import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/chat/data/chat_repository.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_participant_model.dart';
import 'package:hudhud_delivery/features/chat/model/send_chat_message_request.dart';

part 'chat_room_event.dart';
part 'chat_room_state.dart';

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ChatRepository repository;
  final int? currentUserId;

  Timer? _pollTimer;
  int _tempIdCounter = -1;
  final Map<int, SendChatMessageRequest> _pendingRetries = {};

  ChatRoomBloc({
    required this.repository,
    this.currentUserId,
  }) : super(const ChatRoomInitial()) {
    on<OpenChatRoomEvent>(_onOpen);
    on<PollChatMessagesEvent>(_onPoll);
    on<SendTextMessageEvent>(_onSendText);
    on<SendImageMessageEvent>(_onSendImage);
    on<SendFileMessageEvent>(_onSendFile);
    on<SendAudioMessageEvent>(_onSendAudio);
    on<SendLocationMessageEvent>(_onSendLocation);
    on<EditMessageEvent>(_onEdit);
    on<DeleteMessageEvent>(_onDelete);
    on<MarkChatReadEvent>(_onMarkRead);
    on<StartEditMessageEvent>(_onStartEdit);
    on<CancelEditMessageEvent>(_onCancelEdit);
    on<RetrySendMessageEvent>(_onRetry);
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  void _startPolling(int conversationId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!isClosed) add(const PollChatMessagesEvent());
    });
  }

  Future<void> _onOpen(
    OpenChatRoomEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    emit(const ChatRoomLoading());
    try {
      final ChatConversationDetailResult detail;
      if (event.initialDetail != null) {
        detail = event.initialDetail!;
      } else {
        detail = await repository.getConversationWithRetry(
          event.conversationId,
        );
      }
      emit(
        ChatRoomLoaded(
          conversation: detail.conversation,
          messages: detail.messages,
          participants: detail.participants,
        ),
      );
      try {
        await repository.markConversationRead(event.conversationId);
      } catch (_) {}
      _startPolling(event.conversationId);
      if (event.initialDetail != null) {
        add(const PollChatMessagesEvent());
      }
    } catch (e) {
      emit(ChatRoomFailure(e.toString()));
    }
  }

  Future<void> _onPoll(
    PollChatMessagesEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final current = state;
    if (current is! ChatRoomLoaded) return;
    try {
      final detail =
          await repository.getConversation(current.conversation.id);
      final merged = _mergeMessages(current.messages, detail.messages);
      emit(
        current.copyWith(
          conversation: detail.conversation,
          messages: merged,
          participants: detail.participants,
        ),
      );
    } catch (_) {}
  }

  List<ChatMessageModel> _mergeMessages(
    List<ChatMessageModel> existing,
    List<ChatMessageModel> incoming,
  ) {
    final optimistic = existing.where((m) => m.id < 0).toList();
    final map = <int, ChatMessageModel>{};
    for (final m in incoming) {
      map[m.id] = m;
    }
    for (final m in optimistic) {
      if (m.localStatus == ChatMessageStatus.sending ||
          m.localStatus == ChatMessageStatus.failed) {
        map[m.id] = m;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) {
        final at = a.createdAt ?? a.deliveredAt ?? DateTime(1970);
        final bt = b.createdAt ?? b.deliveredAt ?? DateTime(1970);
        return at.compareTo(bt);
      });
    return list;
  }

  Future<void> _onSendText(
    SendTextMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;
    final current = state;
    if (current is! ChatRoomLoaded) return;

    if (current.editingMessageId != null) {
      add(EditMessageEvent(
        messageId: current.editingMessageId!,
        newText: text,
      ));
      return;
    }

    final request = SendChatMessageRequest(
      message: text,
      type: ChatMessageType.text,
    );
    await _sendWithOptimistic(current, request, emit);
  }

  Future<void> _onSendImage(
    SendImageMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final current = state;
    if (current is! ChatRoomLoaded || event.filePaths.isEmpty) return;
    final request = SendChatMessageRequest(
      message: event.caption.isEmpty ? 'Photo' : event.caption,
      type: ChatMessageType.image,
      attachmentFiles: event.filePaths.map(File.new).toList(),
    );
    await _sendWithOptimistic(current, request, emit);
  }

  Future<void> _onSendFile(
    SendFileMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final current = state;
    if (current is! ChatRoomLoaded || event.filePaths.isEmpty) return;
    final request = SendChatMessageRequest(
      message: event.caption.isEmpty ? 'File' : event.caption,
      type: ChatMessageType.file,
      attachmentFiles: event.filePaths.map(File.new).toList(),
    );
    await _sendWithOptimistic(current, request, emit);
  }

  Future<void> _onSendAudio(
    SendAudioMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final current = state;
    if (current is! ChatRoomLoaded) return;
    final request = SendChatMessageRequest(
      message: event.caption.isEmpty ? 'Voice message' : event.caption,
      type: ChatMessageType.audio,
      attachmentFiles: [File(event.filePath)],
    );
    await _sendWithOptimistic(current, request, emit);
  }

  Future<void> _onSendLocation(
    SendLocationMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final current = state;
    if (current is! ChatRoomLoaded) return;
    final request = SendChatMessageRequest(
      message: event.caption.isEmpty ? "I'm at this location" : event.caption,
      type: ChatMessageType.location,
      metadata: {
        'latitude': event.latitude,
        'longitude': event.longitude,
        'address': event.address,
      },
    );
    await _sendWithOptimistic(current, request, emit);
  }

  Future<void> _sendWithOptimistic(
    ChatRoomLoaded current,
    SendChatMessageRequest request,
    Emitter<ChatRoomState> emit,
  ) async {
    final tempId = _tempIdCounter--;
    final optimistic = ChatMessageModel.optimistic(
      tempId: tempId,
      conversationId: current.conversation.id,
      senderId: currentUserId ?? 0,
      body: request.message,
      type: request.type,
      localFilePaths:
          request.attachmentFiles.map((f) => f.path).toList(),
    );
    _pendingRetries[tempId] = request;

    emit(
      current.copyWith(
        messages: [...current.messages, optimistic],
        isSending: true,
      ),
    );

    try {
      final sent = await repository.sendMessage(
        current.conversation.id,
        request,
      );
      _pendingRetries.remove(tempId);
      final updated = current.messages
          .where((m) => m.id != tempId)
          .toList()
        ..add(sent);
      emit(
        (state as ChatRoomLoaded).copyWith(
          messages: updated,
          isSending: false,
        ),
      );
      add(const MarkChatReadEvent());
    } catch (e) {
      final failed = optimistic.copyWith(
        localStatus: ChatMessageStatus.failed,
      );
      final updated = current.messages.map((m) {
        return m.id == tempId ? failed : m;
      }).toList();
      emit(
        current.copyWith(
          messages: updated,
          isSending: false,
        ),
      );
    }
  }

  Future<void> _onRetry(
    RetrySendMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final request = _pendingRetries[event.tempMessageId];
    final current = state;
    if (request == null || current is! ChatRoomLoaded) return;
    final cleaned = current.messages
        .where((m) => m.id != event.tempMessageId)
        .toList();
    emit(current.copyWith(messages: cleaned));
    _pendingRetries.remove(event.tempMessageId);
    await _sendWithOptimistic(
      current.copyWith(messages: cleaned),
      request,
      emit,
    );
  }

  Future<void> _onEdit(
    EditMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final current = state;
    if (current is! ChatRoomLoaded) return;
    try {
      final updated = await repository.editMessage(
        event.messageId,
        event.newText,
      );
      final messages = current.messages.map((m) {
        return m.id == event.messageId ? updated : m;
      }).toList();
      emit(
        current.copyWith(
          messages: messages,
          clearEditing: true,
        ),
      );
    } catch (e) {
      emit(ChatRoomFailure(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final current = state;
    if (current is! ChatRoomLoaded) return;
    try {
      await repository.deleteMessage(event.messageId);
      final messages = current.messages
          .where((m) => m.id != event.messageId)
          .toList();
      emit(current.copyWith(messages: messages));
    } catch (e) {
      emit(ChatRoomFailure(e.toString()));
    }
  }

  Future<void> _onMarkRead(
    MarkChatReadEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final current = state;
    if (current is! ChatRoomLoaded) return;
    try {
      await repository.markConversationRead(current.conversation.id);
    } catch (_) {}
  }

  void _onStartEdit(
    StartEditMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    final current = state;
    if (current is! ChatRoomLoaded) return;
    emit(
      current.copyWith(
        editingMessageId: event.messageId,
        editingDraft: event.currentText,
      ),
    );
  }

  void _onCancelEdit(
    CancelEditMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    final current = state;
    if (current is! ChatRoomLoaded) return;
    emit(current.copyWith(clearEditing: true));
  }
}
