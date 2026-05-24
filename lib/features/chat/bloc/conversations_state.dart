part of 'conversations_bloc.dart';

abstract class ConversationsState {
  const ConversationsState();
}

class ConversationsInitial extends ConversationsState {
  const ConversationsInitial();
}

class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

class ConversationsLoaded extends ConversationsState {
  final List<ChatConversationModel> conversations;
  final List<ChatConversationModel> filtered;
  final int totalUnread;
  final String searchQuery;
  final bool isRefreshing;

  const ConversationsLoaded({
    required this.conversations,
    required this.filtered,
    required this.totalUnread,
    this.searchQuery = '',
    this.isRefreshing = false,
  });

  ConversationsLoaded copyWith({
    List<ChatConversationModel>? conversations,
    List<ChatConversationModel>? filtered,
    int? totalUnread,
    String? searchQuery,
    bool? isRefreshing,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      filtered: filtered ?? this.filtered,
      totalUnread: totalUnread ?? this.totalUnread,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class ConversationsFailure extends ConversationsState {
  final String message;

  const ConversationsFailure(this.message);
}

class SupportConversationCreated extends ConversationsState {
  final ChatOpenConversationResult openResult;

  const SupportConversationCreated(this.openResult);
}
