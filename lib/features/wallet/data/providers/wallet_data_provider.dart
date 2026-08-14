import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/utils/api_error_result.dart';
import '../models/wallet_balance_model.dart';
import '../models/wallet_transaction_model.dart';
import '../../utils/wallet_funding_methods.dart';

class WalletDataProvider {
  final ApiService apiService;

  WalletDataProvider({required this.apiService});

  /// GET /api/wallet
  Future<WalletBalance> getBalance() async {
    final response = await apiService.get(
      ApiConstants.walletBalance,
    );
    return parseWalletBalanceResponse(response.data);
  }

  /// GET /api/wallet/transactions?page=&limit=
  Future<WalletTransactionsResponse> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await apiService.get(
      ApiConstants.walletTransactions,
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return parseWalletTransactionsResponse(response.data);
  }

  /// POST /api/wallet/topup
  Future<WalletMutationResponse> topUp({
    required double amount,
    required String paymentMethodCode,
    required String currency,
    Map<String, dynamic>? paymentDetails,
  }) async {
    final body = buildWalletTopupBody(
      paymentMethodCode: paymentMethodCode,
      amount: amount,
      currency: currency,
      paymentDetails: paymentDetails,
    );
    final response = await apiService.post(
      ApiConstants.walletTopup,
      data: body,
    );
    return WalletMutationResponse.fromApi(response.data, fallbackError: 'Failed to top up');
  }

  /// POST /api/wallet/withdraw
  Future<WalletMutationResponse> withdraw({
    required double amount,
    required String paymentMethodCode,
    Map<String, dynamic>? paymentDetails,
  }) async {
    final body = buildWalletWithdrawBody(
      paymentMethodCode: paymentMethodCode,
      amount: amount,
      paymentDetails: paymentDetails,
    );
    final response = await apiService.post(
      ApiConstants.walletWithdraw,
      data: body,
    );
    return WalletMutationResponse.fromApi(
      response.data,
      fallbackError: 'Failed to withdraw funds',
    );
  }
}

class WalletMutationResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? payment;
  final Map<String, dynamic>? rawData;

  const WalletMutationResponse({
    required this.success,
    required this.message,
    this.payment,
    this.rawData,
  });

  factory WalletMutationResponse.fromApi(
    dynamic data, {
    required String fallbackError,
  }) {
    if (data == null || data is! Map) {
      throw Exception('Invalid wallet mutation response');
    }
    final map = Map<String, dynamic>.from(data);
    final success = map['success'] == true;
    if (!success) {
      final parsed = parseApiErrorResult(map);
      throw Exception(
        parsed.displayMessage.isNotEmpty
            ? parsed.displayMessage
            : fallbackError,
      );
    }
    final message = map['message']?.toString() ?? '';

    final inner = map['data'];
    Map<String, dynamic>? payment;
    Map<String, dynamic>? rawData;
    if (inner is Map) {
      rawData = Map<String, dynamic>.from(inner);
      final paymentRaw = inner['payment'];
      if (paymentRaw is Map) {
        payment = Map<String, dynamic>.from(paymentRaw);
      } else if (inner.containsKey('next_action') ||
          inner.containsKey('payment_id')) {
        // Entire data may be the payment envelope.
        payment = rawData;
      }
    } else if (map.containsKey('next_action') || map.containsKey('payment_id')) {
      payment = map;
    }

    return WalletMutationResponse(
      success: true,
      message: message,
      payment: payment,
      rawData: rawData,
    );
  }
}
