import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/models/notification_model.dart';

import '../data/repository/notifications_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;
  final int? currentUserId;

  NotificationsBloc({
    required this.repository,
    this.currentUserId,
  }) : super(NotificationsInitial()) {
    on<FetchNotificationsEvent>(_onFetchNotifications);
    on<FetchNotificationDetailsEvent>(_onFetchNotificationDetails);
  }

  Future<void> _onFetchNotifications(
    FetchNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    try {
      final notifications =
          await repository.getNotifications(userId: currentUserId);
      emit(NotificationsLoaded(notifications));
    } catch (e) {
      emit(NotificationsFailure(e.toString()));
    }
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
}
