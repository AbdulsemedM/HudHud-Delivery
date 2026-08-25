import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/app/navigation/app_navigator.dart';
import 'package:hudhud_delivery/app/navigation/fcm_notification_router.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/models/notification_model.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/notifications/bloc/notifications_bloc.dart';
import 'package:hudhud_delivery/features/notifications/data/data_provider/notifications_data_provider.dart';
import 'package:hudhud_delivery/features/notifications/data/repository/notifications_repository.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(FetchNotificationsEvent());
  }

  void _refetch(NotificationsState state) {
    final loaded = state is NotificationsLoaded ? state : null;
    context.read<NotificationsBloc>().add(
          FetchNotificationsEvent(
            page: loaded?.page ?? 1,
            perPage: loaded?.perPage ?? 20,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        return ProfileDarkPage(
          title: 'Notifications',
          actions: [
            if (state is NotificationsLoaded && state.unreadCount > 0)
              TextButton(
                onPressed: () {
                  context
                      .read<NotificationsBloc>()
                      .add(MarkAllNotificationsReadEvent());
                },
                child: Text(
                  'Mark all read',
                  style: TextStyle(color: AuthScreenColors.orange),
                ),
              ),
          ],
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationsState state) {
    if (state is NotificationsLoading) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: _NotificationsShimmer(),
      );
    }
    if (state is NotificationsFailure) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AuthScreenColors.textMutedOf(context),
              ),
              SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AuthScreenColors.textSecondaryOf(context),
                ),
              ),
              SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => _refetch(state),
                icon: Icon(
                  Icons.refresh,
                  color: AuthScreenColors.orange,
                ),
                label: Text(
                  'Retry',
                  style: TextStyle(color: AuthScreenColors.orange),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (state is NotificationsLoaded) {
      final grouped = _groupNotificationsByDate(state.notifications);
      if (grouped.isEmpty && state.temporaryError == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('assets/animations/browse.json', width: 160),
              SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(
                  color: AuthScreenColors.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () async => _refetch(state),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 16),
          children: [
            if (state.temporaryError != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Material(
                  color: AuthScreenColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: Icon(
                      Icons.cloud_off_outlined,
                      color: AuthScreenColors.orange,
                    ),
                    title: Text(
                      state.temporaryError!,
                      style: TextStyle(
                        color: AuthScreenColors.textSecondaryOf(context),
                        fontSize: 14,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () => _refetch(state),
                      child: Text(
                        'Retry',
                        style: TextStyle(color: AuthScreenColors.orange),
                      ),
                    ),
                  ),
                ),
              ),
            ...grouped.entries.map((entry) {
              return _NotificationSection(
                title: entry.key,
                notifications: entry.value,
              );
            }),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  Map<String, List<NotificationModel>> _groupNotificationsByDate(
    List<NotificationModel> notifications,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<NotificationModel>> grouped = {};
    for (final n in notifications) {
      final date = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      String key;
      if (date == today) {
        key = 'Today';
      } else if (date == yesterday) {
        key = 'Yesterday';
      } else {
        key = 'Older';
      }
      grouped.putIfAbsent(key, () => []).add(n);
    }
    final order = ['Today', 'Yesterday', 'Older'];
    final sorted = <String, List<NotificationModel>>{};
    for (final k in order) {
      if (grouped.containsKey(k)) {
        sorted[k] = grouped[k]!;
      }
    }
    return sorted;
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<NotificationModel> notifications;

  const _NotificationSection({
    required this.title,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AuthScreenColors.textPrimaryOf(context),
              ),
            ),
          ),
          SizedBox(height: 12),
          ...notifications.map((n) => _NotificationItem(notification: n)),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final iconColor = notification.isRead
        ? AuthScreenColors.textMutedOf(context)
        : AuthScreenColors.orange;
    final timeAgo = _formatTimeAgo(notification.createdAt);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onTap(context),
        child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthScreenColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthScreenColors.surfaceBorderOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        notification.isRead ? FontWeight.w500 : FontWeight.w600,
                    color: AuthScreenColors.textPrimaryOf(context),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: AuthScreenColors.textSecondaryOf(context),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: AuthScreenColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    if (!notification.isRead) {
      context
          .read<NotificationsBloc>()
          .add(MarkNotificationReadEvent(notification.id));
    }
    if (notification.routingData.isEmpty) return;
    final navKey = AppNavigator.navigatorKey;
    if (navKey == null) return;
    await openNotificationFromPayloadMap(
      navKey,
      notification.routingData,
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return '1d ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}w ago';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _NotificationsShimmer extends StatelessWidget {
  const _NotificationsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: AuthScreenColors.surfaceOf(context),
            highlightColor: AuthScreenColors.surfaceBorderOf(context),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AuthScreenColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Creates a NotificationsBloc with repository wired to API.
NotificationsBloc createNotificationsBloc() {
  final authService = AuthService();
  final dataProvider =
      NotificationsDataProvider(apiService: ApiService.instance);
  final repository = NotificationsRepository(dataProvider: dataProvider);
  return NotificationsBloc(
    repository: repository,
    currentUserId: authService.currentUser?.id,
  );
}
