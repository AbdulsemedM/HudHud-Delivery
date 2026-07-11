part of 'notifications_bloc.dart';

@immutable
sealed class NotificationsState {}

final class NotificationsInitial extends NotificationsState {}

final class NotificationsLoading extends NotificationsState {}

final class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  NotificationsLoaded(this.notifications);
}

final class NotificationsFailure extends NotificationsState {
  final String message;
  NotificationsFailure(this.message);
}

final class NotificationDetailsLoading extends NotificationsState {}

final class NotificationDetailsLoaded extends NotificationsState {
  final NotificationModel notification;
  NotificationDetailsLoaded(this.notification);
}

final class NotificationDetailsFailure extends NotificationsState {
  final String message;
  NotificationDetailsFailure(this.message);
}
