part of 'notifications_bloc.dart';

@immutable
sealed class NotificationsState {}

final class NotificationsInitial extends NotificationsState {}

final class NotificationsLoading extends NotificationsState {}

final class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int page;
  final int perPage;
  final int total;
  final String? temporaryError;

  NotificationsLoaded(
    this.notifications, {
    this.unreadCount = 0,
    this.page = 1,
    this.perPage = 20,
    this.total = 0,
    this.temporaryError,
  });

  NotificationsLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    int? page,
    int? perPage,
    int? total,
    String? temporaryError,
    bool clearTemporaryError = false,
  }) {
    return NotificationsLoaded(
      notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
      temporaryError:
          clearTemporaryError ? null : (temporaryError ?? this.temporaryError),
    );
  }
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
