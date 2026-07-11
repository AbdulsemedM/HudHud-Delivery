import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/tips/data/tips_data_provider.dart';
import 'package:hudhud_delivery/features/tips/model/tip_add_wallet_result.dart';
import 'package:hudhud_delivery/features/tips/model/tip_calculate_result.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_query.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_result.dart';
import 'package:hudhud_delivery/features/tips/model/tip_rate_model.dart';

class TipsRepository {
  TipsRepository({TipsDataProvider? dataProvider})
      : _dataProvider =
            dataProvider ?? TipsDataProvider(apiService: ApiService.instance);

  final TipsDataProvider _dataProvider;
  List<TipRateModel> _cachedRates = [];

  List<TipRateModel> get cachedRates => List.unmodifiable(_cachedRates);

  Future<List<TipRateModel>> getRates() async {
    final response = await _dataProvider.getRates();
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final data = response['data'];
    final list = _extractList(data);
    final rates = list
        .map((e) => TipRateModel.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.isActive)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    _cachedRates = rates;
    return rates;
  }

  Future<TipCalculateResult> calculateTip({
    required int orderId,
    required int tipOptionId,
    num? customAmount,
  }) async {
    final response = await _dataProvider.calculateTip(
      orderId: orderId,
      tipOptionId: tipOptionId,
      customAmount: customAmount,
    );
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final data = _extractDataMap(response['data']);
    return TipCalculateResult.fromJson(data);
  }

  Future<TipAddWalletResult> addTipWallet({
    required int orderId,
    required num amount,
    required int tipOptionId,
    required String recipientType,
    String? message,
    bool isAnonymous = false,
  }) async {
    final response = await _dataProvider.addTip(
      orderId: orderId,
      amount: amount,
      tipOptionId: tipOptionId,
      recipientType: recipientType,
      paymentMethod: 'wallet',
      message: message,
      isAnonymous: isAnonymous,
    );
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    final data = _extractDataMap(response['data']);
    return TipAddWalletResult.fromJson(data);
  }

  Future<TipHistoryResult> getHistory({
    TipHistoryQuery query = const TipHistoryQuery(),
  }) async {
    final response = await _dataProvider.getHistory(query);
    if (response['statusCode'] != 200) {
      throw Exception(_clean(response['errorMessage']?.toString() ?? 'Error'));
    }
    return TipHistoryResult.fromResponseData(response['data']);
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> _extractDataMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return data;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    return {};
  }

  String _clean(String message) {
    if (message.startsWith('Exception: ')) message = message.substring(11);
    if (message.startsWith('ApiException: ')) message = message.substring(14);
    return message;
  }
}
