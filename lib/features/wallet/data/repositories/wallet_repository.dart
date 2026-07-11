import '../models/wallet_model.dart';
import '../providers/wallet_data_provider.dart';

class WalletRepository {
  final WalletDataProvider walletDataProvider;

  WalletRepository({required this.walletDataProvider});

  Future<WalletsResponse> getWallets({int page = 1, int perPage = 10}) async {
    return walletDataProvider.getWallets(page: page, perPage: perPage);
  }

  Future<WalletModel?> getWallet(int id) async {
    return walletDataProvider.getWallet(id);
  }

  Future<WalletTransactionsResponse> getTransactions({
    int page = 1,
    int perPage = 10,
  }) async {
    return walletDataProvider.getTransactions(page: page, perPage: perPage);
  }

  Future<AddFundsResponse> addFunds({
    required double amount,
    required String method,
    required String currency,
    int? payerId,
    int? walletId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    return walletDataProvider.addFunds(
      amount: amount,
      method: method,
      currency: currency,
      payerId: payerId,
      walletId: walletId,
      paymentDetails: paymentDetails,
    );
  }

  Future<WithdrawFundsResponse> withdraw({
    required double amount,
    required String method,
    required String currency,
    required int walletId,
    int? payerId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    return walletDataProvider.withdraw(
      amount: amount,
      method: method,
      currency: currency,
      walletId: walletId,
      payerId: payerId,
      paymentDetails: paymentDetails,
    );
  }
}
