import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/utils/api_error_result.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';

class _FakeCourierDataProvider extends CourierDataProvider {
  _FakeCourierDataProvider() : super(apiService: ApiService.instance);

  Map<String, dynamic>? nextCreateResponse;

  @override
  Future<Map<String, dynamic>> createDeliveryRequest({
    required Map<String, dynamic> requestData,
  }) async {
    return nextCreateResponse ??
        {
          'statusCode': 400,
          'data': {
            'success': false,
            'message': 'Insufficient wallet balance',
            'balance': 0,
            'required': 48.67,
            'deficit': 48.67,
          },
          'errorMessage': 'Insufficient wallet balance',
        };
  }
}

void main() {
  group('CourierRepository.createDeliveryRequest errors', () {
    test('maps insufficient wallet balance 400 with deficit', () async {
      final provider = _FakeCourierDataProvider();
      final repo = CourierRepository(courierDataProvider: provider);

      final result = await repo.createDeliveryRequest(
        requestData: {'payment_method': 'wallet'},
      );

      expect(result['success'], isFalse);
      final error = result['error'] as ApiErrorResult?;
      expect(error, isNotNull);
      expect(error!.code, 'insufficient_balance');
      expect(error.deficit, 48.67);
      expect(error.balance, 0);
      expect(error.requiredAmount, 48.67);
      expect(result['message'], contains('Insufficient wallet balance'));
      expect(result['message'], contains('Short by: 48.67'));
    });
  });
}
