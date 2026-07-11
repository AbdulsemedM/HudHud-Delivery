import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';

class WalletDataProvider {
  final ApiService apiService;

  WalletDataProvider({required this.apiService});

  /// GET /api/wallets - fetches user wallets (paginated).
  Future<WalletsResponse> getWallets({int page = 1, int perPage = 10}) async {
    final response = await apiService.get(
      ApiConstants.wallets,
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    final data = response.data;

    if (data == null || data is! Map<String, dynamic>) {
      return const WalletsResponse(wallets: [], currentPage: 1, lastPage: 1, total: 0);
    }

    final inner = data['data'];
    if (inner == null || inner is! Map<String, dynamic>) {
      return const WalletsResponse(wallets: [], currentPage: 1, lastPage: 1, total: 0);
    }

    final list = inner['data'];
    final List<WalletModel> wallets = [];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          wallets.add(WalletModel.fromJson(item));
        }
      }
    }

    final currentPage =
        int.tryParse(inner['current_page']?.toString() ?? '1') ?? 1;
    final lastPage =
        int.tryParse(inner['last_page']?.toString() ?? '1') ?? 1;
    final total = int.tryParse(inner['total']?.toString() ?? '0') ?? 0;

    return WalletsResponse(
      wallets: wallets,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  /// GET /api/wallets/{id} - fetches a single wallet by ID.
  Future<WalletModel?> getWallet(int id) async {
    final response = await apiService.get(
      ApiConstants.replacePathParams(ApiConstants.walletDetails, {'id': id}),
    );
    final data = response.data;

    if (data == null || data is! Map<String, dynamic>) {
      return null;
    }

    final inner = data['data'];
    if (inner == null || inner is! Map<String, dynamic>) {
      return null;
    }

    return WalletModel.fromJson(inner);
  }

  /// GET /api/wallet/transactions - fetches wallet transactions (paginated).
  Future<WalletTransactionsResponse> getTransactions({
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await apiService.get(
      ApiConstants.walletTransactions,
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    final data = response.data;

    if (data == null || data is! Map<String, dynamic>) {
      return const WalletTransactionsResponse(
        transactions: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      );
    }

    final inner = data['data'];
    if (inner == null || inner is! Map<String, dynamic>) {
      return const WalletTransactionsResponse(
        transactions: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      );
    }

    final list = inner['data'];
    final List<WalletTransactionModel> transactions = [];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          transactions.add(WalletTransactionModel.fromJson(item));
        }
      }
    }

    final currentPage =
        int.tryParse(inner['current_page']?.toString() ?? '1') ?? 1;
    final lastPage =
        int.tryParse(inner['last_page']?.toString() ?? '1') ?? 1;
    final total = int.tryParse(inner['total']?.toString() ?? '0') ?? 0;

    return WalletTransactionsResponse(
      transactions: transactions,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  /// POST /api/wallet/add-funds - adds funds to wallet.
  Future<AddFundsResponse> addFunds({
    required double amount,
    required String method,
    required String currency,
    int? payerId,
    int? walletId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    final response = await apiService.post(
      ApiConstants.walletAddFunds,
      data: {
        'amount': amount,
        'method': method,
        'currency': currency,
        if (payerId != null) 'payer_id': payerId,
        if (walletId != null) 'wallet_id': walletId,
        if (paymentDetails != null && paymentDetails.isNotEmpty)
          'payment_details': paymentDetails,
      },
    );
    final data = response.data;

    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from add funds');
    }

    final success = data['success'] == true;
    final message = data['message']?.toString() ?? '';

    if (!success) {
      throw Exception(message.isNotEmpty ? message : 'Failed to add funds');
    }

    final inner = data['data'];
    return AddFundsResponse(
      success: true,
      message: message,
      wallet: inner != null && inner['wallet'] != null
          ? WalletModel.fromJson(inner['wallet'] as Map<String, dynamic>)
          : null,
      payment: inner != null && inner['payment'] != null
          ? inner['payment'] as Map<String, dynamic>
          : null,
    );
  }

  /// POST /api/wallet/withdraw - withdraws funds from wallet.
  Future<WithdrawFundsResponse> withdraw({
    required double amount,
    required String method,
    required String currency,
    required int walletId,
    int? payerId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    final response = await apiService.post(
      ApiConstants.walletWithdraw,
      data: {
        'amount': amount,
        'method': method,
        'currency': currency,
        'wallet_id': walletId,
        if (payerId != null) 'payer_id': payerId,
        if (paymentDetails != null && paymentDetails.isNotEmpty)
          'payment_details': paymentDetails,
      },
    );
    final data = response.data;

    if (data == null || data is! Map<String, dynamic>) {
      throw Exception('Invalid response from withdraw');
    }

    final success = data['success'] == true;
    final message = data['message']?.toString() ?? '';

    if (!success) {
      throw Exception(
          message.isNotEmpty ? message : 'Failed to withdraw funds');
    }

    final inner = data['data'];
    return WithdrawFundsResponse(
      success: true,
      message: message,
      wallet: inner != null && inner['wallet'] != null
          ? WalletModel.fromJson(inner['wallet'] as Map<String, dynamic>)
          : null,
      payment: inner != null && inner['payment'] != null
          ? inner['payment'] as Map<String, dynamic>
          : null,
    );
  }
}

class WithdrawFundsResponse {
  final bool success;
  final String message;
  final WalletModel? wallet;
  final Map<String, dynamic>? payment;

  const WithdrawFundsResponse({
    required this.success,
    required this.message,
    this.wallet,
    this.payment,
  });
}

class AddFundsResponse {
  final bool success;
  final String message;
  final WalletModel? wallet;
  final Map<String, dynamic>? payment;

  const AddFundsResponse({
    required this.success,
    required this.message,
    this.wallet,
    this.payment,
  });
}

class WalletTransactionsResponse {
  final List<WalletTransactionModel> transactions;
  final int currentPage;
  final int lastPage;
  final int total;

  const WalletTransactionsResponse({
    required this.transactions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class WalletsResponse {
  final List<WalletModel> wallets;
  final int currentPage;
  final int lastPage;
  final int total;

  const WalletsResponse({
    required this.wallets,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
