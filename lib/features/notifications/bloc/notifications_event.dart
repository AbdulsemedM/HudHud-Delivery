part of 'notifications_bloc.dart';

@immutable
sealed class NotificationsEvent {}

class FetchNotificationsEvent extends NotificationsEvent {
  final int page;
  final int perPage;

  FetchNotificationsEvent({
    this.page = 1,
    this.perPage = 20,
  });
}

class FetchNotificationDetailsEvent extends NotificationsEvent {
  final String id;
  FetchNotificationDetailsEvent(this.id);
}

class MarkNotificationReadEvent extends NotificationsEvent {
  final String notificationId;
  MarkNotificationReadEvent(this.notificationId);
}

class MarkAllNotificationsReadEvent extends NotificationsEvent {}
