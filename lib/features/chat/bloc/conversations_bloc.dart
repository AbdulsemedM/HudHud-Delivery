import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/chat/data/chat_repository.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_open_conversation_result.dart';

part 'conversations_event.dart';
part 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final ChatRepository repository;
  final int? currentUserId;

  ConversationsBloc({
    required this.repository,
    this.currentUserId,
  }) : super(const ConversationsInitial()) {
    on<LoadConversationsEvent>(_onLoad);
    on<RefreshConversationsEvent>(_onRefresh);
    on<LoadUnreadCountEvent>(_onLoadUnread);
    on<CreateSupportConversationEvent>(_onCreateSupport);
    on<SearchConversationsEvent>(_onSearch);
  }

  Future<void> _onLoad(
    LoadConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(const ConversationsLoading());
    try {
      final result = await repository.getConversations();
      final sorted = _sortConversations(result.conversations);
      emit(
        ConversationsLoaded(
          conversations: sorted,
          filtered: sorted,
          totalUnread: result.totalUnread,
        ),
      );
    } catch (e) {
      emit(ConversationsFailure(e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    final current = state;
    if (current is ConversationsLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    try {
      final result = await repository.getConversations();
      final sorted = _sortConversations(result.conversations);
      final query =
          current is ConversationsLoaded ? current.searchQuery : '';
      emit(
        ConversationsLoaded(
          conversations: sorted,
          filtered: _filter(sorted, query),
          totalUnread: result.totalUnread,
          searchQuery: query,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (current is ConversationsLoaded) {
        emit(current.copyWith(isRefreshing: false));
      } else {
        emit(ConversationsFailure(e.toString()));
      }
    }
  }

  Future<void> _onLoadUnread(
    LoadUnreadCountEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    final current = state;
    if (current is! ConversationsLoaded) return;
    try {
      final count = await repository.getUnreadCount();
      emit(current.copyWith(totalUnread: count));
    } catch (_) {}
  }

  Future<void> _onCreateSupport(
    CreateSupportConversationEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      final result = await repository.createSupportConversation(event.subject);
      emit(SupportConversationCreated(result));
      add(const RefreshConversationsEvent());
    } catch (e) {
      emit(ConversationsFailure(e.toString()));
    }
  }

  void _onSearch(
    SearchConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) {
    final current = state;
    if (current is! ConversationsLoaded) return;
    emit(
      current.copyWith(
        searchQuery: event.query,
        filtered: _filter(current.conversations, event.query),
      ),
    );
  }

  List<ChatConversationModel> _sortConversations(
    List<ChatConversationModel> list,
  ) {
    final seenIds = <int>{};
    final deduped = <ChatConversationModel>[];
    for (final c in list) {
      if (seenIds.add(c.id)) deduped.add(c);
    }
    deduped.sort((a, b) {
      final at = a.lastMessageAt ?? a.createdAt ?? DateTime(1970);
      final bt = b.lastMessageAt ?? b.createdAt ?? DateTime(1970);
      return bt.compareTo(at);
    });
    return deduped;
  }

  List<ChatConversationModel> _filter(
    List<ChatConversationModel> list,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((c) {
      final title = c.displayTitle(currentUserId: currentUserId).toLowerCase();
      final preview = c.lastPreviewText().toLowerCase();
      final subtitle = c.subtitleLine().toLowerCase();
      final name = c.counterpartyName(currentUserId)?.toLowerCase() ?? '';
      return title.contains(q) ||
          preview.contains(q) ||
          subtitle.contains(q) ||
          name.contains(q);
    }).toList();
  }
}
