/// Polling intervals aligned with HudHud chat API guidance (Aug 2026).
class ChatPollingConfig {
  ChatPollingConfig._();

  /// Open conversation: 3–5s recommended; use middle value.
  static const Duration openConversationInterval = Duration(seconds: 4);

  /// Conversation list while visible: 15–30s recommended.
  static const Duration conversationListInterval = Duration(seconds: 20);

  /// Unread badge only: 30–60s recommended.
  static const Duration unreadBadgeInterval = Duration(seconds: 45);
}
