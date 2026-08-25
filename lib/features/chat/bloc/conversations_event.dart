part of 'conversations_bloc.dart';

abstract class ConversationsEvent {
  const ConversationsEvent();
}

class LoadConversationsEvent extends ConversationsEvent {
  const LoadConversationsEvent();
}

class RefreshConversationsEvent extends ConversationsEvent {
  const RefreshConversationsEvent();
}

class LoadUnreadCountEvent extends ConversationsEvent {
  const LoadUnreadCountEvent();
}

class CreateSupportConversationEvent extends ConversationsEvent {
  final String subject;

  const CreateSupportConversationEvent(this.subject);
}

class SearchConversationsEvent extends ConversationsEvent {
  final String query;

  const SearchConversationsEvent(this.query);
}
