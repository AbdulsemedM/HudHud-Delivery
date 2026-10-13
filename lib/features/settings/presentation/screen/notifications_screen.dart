import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/app/navigation/app_navigator.dart';
import 'package:hudhud_delivery/app/navigation/fcm_notification_router.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
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
                style: TextButton.styleFrom(
                  foregroundColor: AuthScreenColors.orange,
                  minimumSize: const Size(48, 48),
                ),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AuthScreenColors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
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
      final dark = AuthScreenColors.isDark(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      AppColors.errorColor.withValues(alpha: dark ? 0.2 : 0.1),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 46,
                  color: AppColors.errorColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AuthScreenColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => _refetch(state),
                  style: FilledButton.styleFrom(
                    backgroundColor: AuthScreenColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
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
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(
                  color: AuthScreenColors.textPrimaryOf(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        color: AuthScreenColors.orange,
        onRefresh: () async => _refetch(state),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            if (state.temporaryError != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Material(
                  color: AuthScreenColors.surfaceOf(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AuthScreenColors.surfaceBorderOf(context),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.cloud_off_rounded,
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
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AuthScreenColors.textMutedOf(context),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
    final dark = AuthScreenColors.isDark(context);
    final unread = !notification.isRead;
    final iconColor = unread
        ? AuthScreenColors.orange
        : AuthScreenColors.textMutedOf(context);
    final timeAgo = _formatTimeAgo(notification.createdAt);
    final radius = BorderRadius.circular(20);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppColors.softShadow(context),
        ),
        child: Material(
          color: AuthScreenColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: dark
                ? BorderSide(color: AuthScreenColors.surfaceBorderOf(context))
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _onTap(context),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: unread
                          ? (dark
                              ? AppColors.orangeTintDark
                              : AppColors.orangeTint)
                          : AuthScreenColors.surfaceBorderOf(context)
                              .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      unread
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_rounded,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color:
                                      AuthScreenColors.textPrimaryOf(context),
                                ),
                              ),
                            ),
                            if (unread)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(left: 8, top: 5),
                                decoration: const BoxDecoration(
                                  color: AuthScreenColors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: AuthScreenColors.textSecondaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
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
            baseColor: AuthScreenColors.surfaceBorderOf(context),
            highlightColor: AuthScreenColors.surfaceOf(context),
            child: Container(
              height: 84,
              decoration: BoxDecoration(
                color: AuthScreenColors.surfaceBorderOf(context),
                borderRadius: BorderRadius.circular(20),
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
