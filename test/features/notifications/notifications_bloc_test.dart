import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/notifications/bloc/notifications_bloc.dart';
import 'package:hudhud_delivery/features/notifications/data/data_provider/notifications_data_provider.dart';
import 'package:hudhud_delivery/features/notifications/data/repository/notifications_repository.dart';

class _FakeNotificationsDataProvider implements NotificationsDataProvider {
  _FakeNotificationsDataProvider(this._onGet);

  final Map<String, dynamic> Function() _onGet;
  int getCalls = 0;

  @override
  ApiService get apiService => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    getCalls++;
    return _onGet();
  }

  @override
  Future<Map<String, dynamic>> getNotificationById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> markRead(String notificationId) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> markAllRead() async {
    throw UnimplementedError();
  }
}

void main() {
  Map<String, dynamic> successBody() {
    return {
      'statusCode': 200,
      'data': {
        'data': [
          {
            'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
            'title': 'Order delivered',
            'message': 'Your order has been delivered.',
            'data': {},
            'read_at': null,
            'is_read': false,
            'created_at': '2026-08-17T10:42:46.000000Z',
          },
        ],
        'meta': {
          'unread_count': 3,
          'total': 1,
          'per_page': 20,
          'current_page': 1,
          'last_page': 1,
        },
      },
      'errorMessage': null,
    };
  }

  Map<String, dynamic> unavailableBody() {
    return {
      'statusCode': 503,
      'data': {
        'success': false,
        'message': 'Unable to retrieve notifications at this time.',
        'data': [],
        'meta': {
          'unread_count': 0,
          'total': 0,
          'per_page': 20,
          'current_page': 1,
          'last_page': 1,
        },
      },
      'errorMessage': 'Unable to retrieve notifications at this time.',
    };
  }

  test('503 after a loaded list does not emit NotificationsLoading', () async {
    var calls = 0;
    final provider = _FakeNotificationsDataProvider(() {
      calls++;
      if (calls == 1) return successBody();
      return unavailableBody();
    });
    final bloc = NotificationsBloc(
      repository: NotificationsRepository(dataProvider: provider),
      backoffForRetry: (_) => Duration.zero,
    );

    final states = <NotificationsState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(FetchNotificationsEvent());
    await bloc.stream.firstWhere((s) => s is NotificationsLoaded);

    expect(states.whereType<NotificationsLoading>(), hasLength(1));
    expect(states.last, isA<NotificationsLoaded>());

    bloc.add(FetchNotificationsEvent());
    await bloc.stream.firstWhere(
      (s) => s is NotificationsLoaded && s.temporaryError != null,
    );

    expect(states.whereType<NotificationsLoading>(), hasLength(1));
    final last = states.last as NotificationsLoaded;
    expect(last.temporaryError, isNotNull);

    await sub.cancel();
    await bloc.close();
  });
}
