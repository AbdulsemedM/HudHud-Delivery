class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://api.hudhuddelivery.com/api/';

  // Timeout values (in milliseconds)
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // API Endpoints
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';

  // User endpoints
  static const String users = '/users';
  static const String profile = '$users/profile';
  static const String updateProfile = '$users/profile';
  static const String changePassword = '$users/change-password';

  // Restaurant endpoints
  static const String restaurants = '/restaurants';
  static const String restaurantDetails = '$restaurants/{id}';
  static const String restaurantMenu = '$restaurants/{id}/menu';

  // Order endpoints
  static const String orders = '/orders';
  static const String orderDetails = '$orders/{id}';
  static const String createOrder = orders;
  static const String cancelOrder = '$orders/{id}/cancel';
  static const String orderHistory = '$orders/history';

  // Delivery endpoints
  static const String delivery = '/delivery';
  static const String trackOrder = '$delivery/track/{orderId}';
  static const String deliveryStatus = '$delivery/status/{orderId}';

  // Payment endpoints
  static const String payments = '/payments';
  static const String paymentMethods = '$payments/methods';
  static const String processPayment = '$payments/process';

  // Wallet endpoints
  static const String wallet = '/wallet';
  static const String walletBalance = '$wallet/balance';
  static const String walletTransactions = '$wallet/transactions';
  static const String addMoney = '$wallet/add-money';

  // Settings endpoints
  static const String settings = '/settings';
  static const String notifications = '$settings/notifications';
  static const String preferences = '$settings/preferences';

  // Helper method to replace path parameters
  static String replacePathParams(
      String endpoint, Map<String, dynamic> params) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}
