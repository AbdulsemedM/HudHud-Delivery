import '../../../../core/api/api_constants.dart';
import '../../../../core/api/api_service.dart';

class PaymentDataProvider {
  final ApiService apiService;

  PaymentDataProvider({required this.apiService});

  /// GET /api/payments - fetches payment transactions and extracts unique payment types.
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.payments.replaceFirst('/', '')}',
      );
      final data = response.data;

      if (data == null || data is! Map<String, dynamic>) {
        return _defaultPaymentMethods();
      }

      final list = data['data'];
      if (list == null || list is! List) {
        return _defaultPaymentMethods();
      }

      final Set<String> methods = {};
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final method = item['method'] as String?;
          if (method != null && method.isNotEmpty) {
            methods.add(method);
          }
        }
      }

      if (methods.isEmpty) {
        return _defaultPaymentMethods();
      }

      return methods.map((method) => _paymentMethodFromType(method)).toList();
    } on ApiException {
      return _defaultPaymentMethods();
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  List<Map<String, dynamic>> _defaultPaymentMethods() {
    return [
      _paymentMethodFromType('wallet'),
      _paymentMethodFromType('card'),
      _paymentMethodFromType('cash_on_delivery'),
    ];
  }

  Map<String, dynamic> _paymentMethodFromType(String method) {
    switch (method) {
      case 'wallet':
        return {
          'id': 'wallet',
          'name': 'Wallet',
          'description': 'Pay with your wallet balance',
          'icon': null,
          'enabled': true,
        };
      case 'card':
        return {
          'id': 'card',
          'name': 'Card',
          'description': 'Pay with debit or credit card',
          'icon': null,
          'enabled': true,
        };
      case 'cash_on_delivery':
        return {
          'id': 'cash_on_delivery',
          'name': 'Cash on Delivery',
          'description': 'Pay when your order arrives',
          'icon': null,
          'enabled': true,
        };
      case 'mpesa':
        return {
          'id': 'mpesa',
          'name': 'M-Pesa',
          'description': 'Pay with M-Pesa mobile money',
          'icon': null,
          'enabled': true,
        };
      default:
        return {
          'id': method,
          'name': _formatMethodName(method),
          'description': 'Pay with ${_formatMethodName(method)}',
          'icon': null,
          'enabled': true,
        };
    }
  }

  String _formatMethodName(String method) {
    return method
        .split('_')
        .map((e) => e.isEmpty ? '' : '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
  }

  Future<Map<String, dynamic>> processPayment({
    required String paymentMethod,
    required double amount,
    required String orderId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.payments.replaceFirst('/', '')}/process',
        data: {
          'payment_method': paymentMethod,
          'amount': amount,
          'order_id': orderId,
          'payment_details': paymentDetails ?? {},
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<Map<String, dynamic>> validatePayment({
    required String transactionId,
    required String paymentMethod,
  }) async {
    try {
      final response = await apiService.post(
        '/payments/validate',
        data: {
          'transaction_id': transactionId,
          'payment_method': paymentMethod,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to validate payment: $e');
    }
  }
}
