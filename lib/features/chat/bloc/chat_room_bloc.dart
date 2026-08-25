import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/chat/data/chat_repository.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_participant_model.dart';
import 'package:hudhud_delivery/features/chat/model/send_chat_message_request.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_polling_config.dart';

part 'chat_room_event.dart';
part 'chat_room_state.dart';

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ChatRepository repository;
  final int? currentUserId;
  final int? packageDeliveryId;

  Timer? _pollTimer;
  int? _pollConversationId;
  bool _pollInFlight = false;
  bool _sendInFlight = false;
  int _tempIdCounter = -1;
  final Map<int, SendChatMessageRequest> _pendingRetries = {};

  ChatRoomBloc({
    required this.repository,
    this.currentUserId,
    this.packageDeliveryId,
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
    on<PauseChatPollingEvent>(_onPausePolling);
    on<ResumeChatPollingEvent>(_onResumePolling);
    on<RejoinChatEvent>(_onRejoin);
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }

  void _startPolling(int conversationId) {
    _pollConversationId = conversationId;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(ChatPollingConfig.openConversationInterval, (_) {
      if (!isClosed && !_pollInFlight && !_sendInFlight) {
        add(const PollChatMessagesEvent());
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _onPausePolling(
    PauseChatPollingEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    _stopPolling();
  }

  void _onResumePolling(
    ResumeChatPollingEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    final conversationId = _pollConversationId;
    if (conversationId == null || state is! ChatRoomLoaded) return;
    _startPolling(conversationId);
    if (!_pollInFlight && !_sendInFlight) {
      add(const PollChatMessagesEvent());
    }
  }

  Future<void> _onOpen(
    OpenChatRoomEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      if (event.initialDetail != null) {
        final detail = event.initialDetail!;
        emit(
          ChatRoomLoaded(
            conversation: detail.conversation,
            messages: detail.messages,
            participants: detail.participants,
            isLoadingHistory: detail.messages.isEmpty && !detail.hasLeft,
            hasLeft: detail.hasLeft,
          ),
        );
        _startPolling(event.conversationId);
        unawaited(_markReadAndRefresh(event.conversationId));
        return;
      }

      emit(const ChatRoomLoading());
      final detail = packageDeliveryId != null
          ? await repository.getPackageDeliveryConversation(
              packageDeliveryId!,
            )
          : await repository.getConversationWithRetry(
              event.conversationId,
            );
      emit(
        ChatRoomLoaded(
          conversation: detail.conversation,
          messages: detail.messages,
          participants: detail.participants,
          isLoadingHistory: false,
          hasLeft: detail.hasLeft,
        ),
      );
      _startPolling(event.conversationId);
      unawaited(_markReadAndRefresh(event.conversationId));
    } catch (e) {
      emit(ChatRoomFailure(e.toString()));
    }
  }

  Future<void> _markReadAndRefresh(int conversationId) async {
    try {
      if (packageDeliveryId != null) {
        await repository.markPackageDeliveryRead(packageDeliveryId!);
      } else {
        await repository.markConversationRead(conversationId);
      }
    } catch (_) {}
    if (!isClosed) add(const PollChatMessagesEvent());
  }

  Future<ChatConversationDetailResult> _fetchConversationDetail(
    ChatRoomLoaded current,
  ) {
    if (packageDeliveryId != null) {
      return repository.getPackageDeliveryConversation(packageDeliveryId!);
    }
    return repository.getConversation(current.conversation.id);
  }

  Future<void> _onPoll(
    PollChatMessagesEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final current = state;
    if (current is! ChatRoomLoaded || _pollInFlight || _sendInFlight) return;
    _pollInFlight = true;
    try {
      final detail = await _fetchConversationDetail(current);
      final merged = _mergeMessages(current.messages, detail.messages);
      if (!_messagesChanged(current.messages, merged) &&
          !current.isLoadingHistory &&
          current.hasLeft == detail.hasLeft) {
        return;
      }
      emit(
        current.copyWith(
          conversation: detail.conversation,
          messages: merged,
          participants: detail.participants,
          isLoadingHistory: false,
          hasLeft: detail.hasLeft,
        ),
      );
    } catch (_) {
      if (current.isLoadingHistory) {
        emit(current.copyWith(isLoadingHistory: false));
      }
    } finally {
      _pollInFlight = false;
    }
  }

  bool _messagesChanged(
    List<ChatMessageModel> before,
    List<ChatMessageModel> after,
  ) {
    if (before.length != after.length) return true;
    for (var i = 0; i < before.length; i++) {
      final a = before[i];
      final b = after[i];
      if (a.id != b.id ||
          a.body != b.body ||
          a.isRead != b.isRead ||
          a.isDelivered != b.isDelivered ||
          a.localStatus != b.localStatus) {
        return true;
      }
    }
    return false;
  }

  bool _matchesOptimistic(ChatMessageModel server, ChatMessageModel optimistic) {
    if (server.senderId != optimistic.senderId) return false;
    if (server.type != optimistic.type) return false;
    if (server.body.trim() != optimistic.body.trim()) return false;
    final serverTime = server.createdAt ?? server.deliveredAt;
    final optimisticTime = optimistic.createdAt;
    if (serverTime == null || optimisticTime == null) return true;
    return serverTime.difference(optimisticTime).inMinutes.abs() <= 2;
  }

  List<ChatMessageModel> _mergeMessages(
    List<ChatMessageModel> existing,
    List<ChatMessageModel> incoming,
  ) {
    final incomingIds = <int>{};
    final serverIncoming = <ChatMessageModel>[];
    for (final m in incoming) {
      if (m.id <= 0) continue;
      if (!incomingIds.add(m.id)) continue;
      serverIncoming.add(m);
    }

    final keptPrior = <ChatMessageModel>[];
    final optimistic = <ChatMessageModel>[];
    for (final m in existing) {
      if (m.id < 0) {
        if (m.localStatus != ChatMessageStatus.sending &&
            m.localStatus != ChatMessageStatus.failed) {
          continue;
        }
        final hasServerCopy = incoming.any((s) => _matchesOptimistic(s, m));
        if (!hasServerCopy) optimistic.add(m);
        continue;
      }
      if (!incomingIds.contains(m.id)) {
        keptPrior.add(m);
      }
    }

    // Server order is authoritative. Keep older local window messages first,
    // then the API window, then unconfirmed optimistic sends.
    return [...keptPrior, ...serverIncoming, ...optimistic];
  }

  Future<void> _onSendText(
    SendTextMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;
    final current = state;
    if (current is! ChatRoomLoaded || current.hasLeft) return;

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
    if (current is! ChatRoomLoaded ||
        current.hasLeft ||
        event.filePaths.isEmpty) {
      return;
    }
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
    if (current is! ChatRoomLoaded ||
        current.hasLeft ||
        event.filePaths.isEmpty) {
      return;
    }
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
    if (current is! ChatRoomLoaded || current.hasLeft) return;
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
    if (current is! ChatRoomLoaded || current.hasLeft) return;
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

    _sendInFlight = true;
    try {
      final sent = packageDeliveryId != null
          ? await repository.sendPackageDeliveryMessage(
              packageDeliveryId!,
              request,
            )
          : await repository.sendMessage(
              current.conversation.id,
              request,
            );
      _pendingRetries.remove(tempId);
      final loaded = state;
      if (loaded is! ChatRoomLoaded) return;
      final updated = loaded.messages
          .where((m) => m.id != tempId)
          .toList()
        ..add(sent);
      emit(
        loaded.copyWith(
          messages: updated,
          isSending: false,
        ),
      );
      if (!_pollInFlight) add(const PollChatMessagesEvent());
      add(const MarkChatReadEvent());
    } catch (e) {
      final loaded = state;
      if (loaded is! ChatRoomLoaded) return;
      final failed = optimistic.copyWith(
        localStatus: ChatMessageStatus.failed,
      );
      final messages = loaded.messages.any((m) => m.id == tempId)
          ? loaded.messages
              .map((m) => m.id == tempId ? failed : m)
              .toList(growable: false)
          : [...loaded.messages, failed];
      emit(
        loaded.copyWith(
          messages: messages,
          isSending: false,
        ),
      );
      unawaited(_syncAfterSendError(tempId, optimistic));
    } finally {
      _sendInFlight = false;
    }
  }

  /// If POST timed out, the server may still have saved the message — refresh once.
  Future<void> _syncAfterSendError(
    int tempId,
    ChatMessageModel optimistic,
  ) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (isClosed || _sendInFlight) return;
    final loaded = state;
    if (loaded is! ChatRoomLoaded) return;
    try {
      final detail = await _fetchConversationDetail(loaded);
      if (detail.messages.any((m) => _matchesOptimistic(m, optimistic))) {
        _pendingRetries.remove(tempId);
      }
    } catch (_) {}
    if (!isClosed && !_pollInFlight && !_sendInFlight) {
      add(const PollChatMessagesEvent());
    }
  }

  Future<void> _onRetry(
    RetrySendMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final request = _pendingRetries[event.tempMessageId];
    final current = state;
    if (request == null || current is! ChatRoomLoaded || current.hasLeft) {
      return;
    }
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
      if (packageDeliveryId != null) {
        await repository.markPackageDeliveryRead(packageDeliveryId!);
      } else {
        await repository.markConversationRead(current.conversation.id);
      }
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

  Future<void> _onRejoin(
    RejoinChatEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final current = state;
    if (current is! ChatRoomLoaded || !current.hasLeft || current.isRejoining) {
      return;
    }
    emit(current.copyWith(isRejoining: true));
    try {
      if (packageDeliveryId != null) {
        await repository.rejoinPackageDelivery(packageDeliveryId!);
      } else {
        await repository.rejoinConversation(current.conversation.id);
      }
      final detail = await _fetchConversationDetail(current);
      emit(
        current.copyWith(
          conversation: detail.conversation,
          messages: _mergeMessages(current.messages, detail.messages),
          participants: detail.participants,
          hasLeft: detail.hasLeft,
          isRejoining: false,
          isLoadingHistory: false,
        ),
      );
    } catch (e) {
      emit(current.copyWith(isRejoining: false));
    }
  }
}
