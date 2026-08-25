import '../models/wallet_balance_model.dart';
import '../models/wallet_transaction_model.dart';
import '../providers/wallet_data_provider.dart';

class WalletRepository {
  final WalletDataProvider walletDataProvider;

  WalletRepository({required this.walletDataProvider});

  Future<WalletBalance> getBalance() async {
    return walletDataProvider.getBalance();
  }

  Future<WalletTransactionsResponse> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    return walletDataProvider.getTransactions(page: page, limit: limit);
  }

  Future<WalletMutationResponse> topUp({
    required double amount,
    required String paymentMethodCode,
    required String currency,
    Map<String, dynamic>? paymentDetails,
    String? idempotencyKey,
  }) async {
    return walletDataProvider.topUp(
      amount: amount,
      paymentMethodCode: paymentMethodCode,
      currency: currency,
      paymentDetails: paymentDetails,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<WalletMutationResponse> withdraw({
    required double amount,
    required String paymentMethodCode,
    required String currency,
    required int walletId,
    Map<String, dynamic>? paymentDetails,
    String? idempotencyKey,
  }) async {
    return walletDataProvider.withdraw(
      amount: amount,
      paymentMethodCode: paymentMethodCode,
      currency: currency,
      walletId: walletId,
      paymentDetails: paymentDetails,
      idempotencyKey: idempotencyKey,
    );
  }
}
