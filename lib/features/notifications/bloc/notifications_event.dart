part of 'notifications_bloc.dart';

@immutable
sealed class NotificationsEvent {}

class FetchNotificationsEvent extends NotificationsEvent {}

class FetchNotificationDetailsEvent extends NotificationsEvent {
  final int id;
  FetchNotificationDetailsEvent(this.id);
}
