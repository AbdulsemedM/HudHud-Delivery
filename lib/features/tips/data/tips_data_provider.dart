import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_query.dart';

class TipsDataProvider {
  final ApiService apiService;

  TipsDataProvider({required this.apiService});

  String _url(String path) => '${ApiConstants.baseUrl}$path';

  Future<Map<String, dynamic>> _wrap(Future<dynamic> Function() call) async {
    try {
      final response = await call();
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode ?? 500,
        'data': e.data,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getRates() {
    return _wrap(() => apiService.get(_url(ApiConstants.tipsRates)));
  }

  Future<Map<String, dynamic>> calculateTip({
    required int orderId,
    required int tipOptionId,
    num? customAmount,
  }) {
    final body = <String, dynamic>{
      'order_id': orderId,
      'tip_option_id': tipOptionId,
    };
    if (customAmount != null) {
      body['custom_amount'] = customAmount;
    }
    return _wrap(
      () => apiService.post(_url(ApiConstants.tipsCalculate), data: body),
    );
  }

  Future<Map<String, dynamic>> addTip({
    required int orderId,
    required num amount,
    required int tipOptionId,
    required String recipientType,
    required String paymentMethod,
    String? message,
    bool isAnonymous = false,
  }) {
    return _wrap(
      () => apiService.post(
        _url(ApiConstants.tipsAdd),
        data: {
          'order_id': orderId,
          'amount': amount,
          'tip_option_id': tipOptionId,
          'recipient_type': recipientType,
          'payment_method': paymentMethod,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
          'is_anonymous': isAnonymous,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getHistory(TipHistoryQuery query) {
    return _wrap(
      () => apiService.get(
        _url(ApiConstants.tipsHistory),
        queryParameters: query.toParams(),
      ),
    );
  }
}
