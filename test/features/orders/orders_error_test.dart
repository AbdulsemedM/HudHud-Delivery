import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/orders/data/providers/orders_data_provider.dart';
import 'package:hudhud_delivery/features/orders/data/repositories/orders_repository.dart';

/// Returns a canned response instead of calling the API.
class _FakeProvider implements OrdersDataProvider {
  _FakeProvider(this.response);
  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> fetchCustomerOrders({
    int page = 1,
    int perPage = 15,
    String? status,
  }) async =>
      response;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // Test report issue 1: My deliveries showed
  // "OrdersRepositoryException: You do not have permission..." under a
  // Wi-Fi-off icon.
  test('403 keeps its status code and has no class-name prefix', () async {
    final repo = OrdersRepositoryImpl(
      dataProvider: _FakeProvider({
        'statusCode': 403,
        'data': {'message': 'Forbidden'},
        'errorMessage': 'You do not have permission to perform this action.',
      }),
    );

    await expectLater(
      repo.fetchCustomerOrders(),
      throwsA(
        isA<OrdersRepositoryException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.isForbidden, 'isForbidden', true)
            .having(
              (e) => e.toString(),
              'toString',
              'You do not have permission to perform this action.',
            ),
      ),
    );
  });

  test('no response (connection error) has a null status code', () async {
    final repo = OrdersRepositoryImpl(
      dataProvider: _FakeProvider({
        'statusCode': null,
        'data': null,
        'errorMessage': 'Connection error. Please check your internet connection.',
      }),
    );

    await expectLater(
      repo.fetchCustomerOrders(),
      throwsA(
        isA<OrdersRepositoryException>()
            .having((e) => e.statusCode, 'statusCode', isNull),
      ),
    );
  });
}
