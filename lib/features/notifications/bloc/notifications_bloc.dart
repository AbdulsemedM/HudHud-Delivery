import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/models/notification_model.dart';

import '../data/repository/notifications_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  static const _backoffSeconds = [2, 4, 8];

  final NotificationsRepository repository;
  final int? currentUserId;
  final Duration Function(int retryIndex)? backoffForRetry;

  NotificationsBloc({
    required this.repository,
    this.currentUserId,
    this.backoffForRetry,
  }) : super(NotificationsInitial()) {
    on<FetchNotificationsEvent>(_onFetchNotifications);
    on<FetchNotificationDetailsEvent>(_onFetchNotificationDetails);
    on<MarkNotificationReadEvent>(_onMarkRead);
    on<MarkAllNotificationsReadEvent>(_onMarkAllRead);
  }

  Duration _backoff(int retryIndex) {
    if (backoffForRetry != null) return backoffForRetry!(retryIndex);
    return Duration(seconds: _backoffSeconds[retryIndex]);
  }

  Future<void> _onFetchNotifications(
    FetchNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final previousLoaded =
        state is NotificationsLoaded ? state as NotificationsLoaded : null;
    if (previousLoaded == null) {
      emit(NotificationsLoading());
    }

    Object? lastError;
    for (var attempt = 0; attempt <= _backoffSeconds.length; attempt++) {
      if (attempt > 0) {
        await Future.delayed(_backoff(attempt - 1));
      }
      try {
        final result = await repository.getNotifications(
          userId: currentUserId,
          page: event.page,
          perPage: event.perPage,
        );
        emit(
          NotificationsLoaded(
            result.notifications,
            unreadCount: result.unreadCount,
            page: result.currentPage,
            perPage: result.perPage,
            total: result.total,
          ),
        );
        return;
      } on NotificationsFetchException catch (e) {
        lastError = e;
        if (e.isForbidden) {
          emit(
            NotificationsFailure(
              e.message.isNotEmpty
                  ? e.message
                  : 'You do not have permission to perform this action.',
            ),
          );
          return;
        }
        if (e.isUnauthorized) {
          emit(NotificationsFailure(e.message));
          return;
        }
        if (!e.isUnavailable) {
          break;
        }
      } catch (e) {
        lastError = e;
        break;
      }
    }

    final message = lastError is NotificationsFetchException
        ? lastError.message
        : lastError?.toString() ?? 'Failed to fetch notifications';
    if (previousLoaded != null) {
      emit(previousLoaded.copyWith(temporaryError: message));
      return;
    }
    emit(NotificationsFailure(message));
  }

  Future<void> _onFetchNotificationDetails(
    FetchNotificationDetailsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationDetailsLoading());
    try {
      final notification = await repository.getNotificationById(event.id);
      if (notification != null) {
        emit(NotificationDetailsLoaded(notification));
      } else {
        emit(NotificationDetailsFailure('Notification not found'));
      }
    } catch (e) {
      emit(NotificationDetailsFailure(e.toString()));
    }
  }

  Future<void> _onMarkRead(
    MarkNotificationReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    try {
      await repository.markRead(event.notificationId);
      var unreadCount = current.unreadCount;
      final notifications = current.notifications.map((n) {
        if (n.id != event.notificationId || n.isRead) return n;
        unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
        return n.copyWith(isRead: true);
      }).toList();
      emit(
        current.copyWith(
          notifications: notifications,
          unreadCount: unreadCount,
          clearTemporaryError: true,
        ),
      );
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    try {
      await repository.markAllRead();
      emit(
        current.copyWith(
          notifications: current.notifications
              .map((n) => n.isRead ? n : n.copyWith(isRead: true))
              .toList(),
          unreadCount: 0,
          clearTemporaryError: true,
        ),
      );
    } catch (_) {}
  }
}
