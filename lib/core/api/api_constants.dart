class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://hudapi.mbitrix.com/api/';

  // Timeout values (in milliseconds)
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // API Endpoints
  static const String auth = '/auth';
  static const String login = 'login';
  static const String register = 'register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';

  // FCM endpoints
  static const String fcmToken = 'fcm/token';

  // User endpoints
  static const String users = '/users';
  static const String profile =
      'profile'; // GET /api/profile returns user object at root
  static const String updateProfile = '$users/profile';
  static const String changePassword = '$users/change-password';
  static const String updatePassword = 'update-password';
  static const String sendEmailVerification = 'send-email-verification';
  static const String verifyEmail = 'verify-email';
  static const String sendPhoneVerificationCode =
      'send-phone-verification-code';
  static const String verifyPhone = 'verify-phone';

  // Restaurant endpoints
  static const String restaurants = '/restaurants';
  static const String restaurantDetails = '$restaurants/{id}';
  static const String restaurantMenu = '$restaurants/{id}/menu';

  // Order endpoints (GET /api/orders fetches all orders)
  static const String orders = 'orders';
  static const String orderDetails = '$orders/{id}';
  static const String orderTrack = '$orders/{id}/track';
  static const String createOrder = orders;
  static const String cancelOrder = '$orders/{id}/cancel';
  static const String orderHistory = '$orders/history';

  // Customer order creation - POST /api/customer/orders
  static const String customerOrders = 'customer/orders';
  static const String customerOrdersAvailable = 'customer/orders/available';
  static const String customerOrderRate = 'customer/orders/{id}/rate';
  static const String customerOrderCancel = 'customer/orders/{id}/cancel';

  // Delivery endpoints
  static const String delivery = '/delivery';
  static const String trackOrder = '$delivery/track/{orderId}';
  static const String deliveryStatus = '$delivery/status/{orderId}';

  // Payment endpoints
  static const String payments = '/payments';
  static const String paymentMethods = 'payment-methods';
  static const String processPayment = '$payments/process';

  // Wallet endpoints
  static const String wallets = 'wallets';
  static const String walletDetails = '$wallets/{id}';
  static const String wallet = 'wallet';
  static const String walletBalance = '$wallet/balance';
  static const String walletTransactions = '$wallet/transactions';
  static const String walletAddFunds = '$wallet/add-funds';
  static const String walletWithdraw = '$wallet/withdraw';

  // Categories endpoints (requires auth token)
  static const String categories = 'categories';

  // Notifications endpoints (GET /api/notifications, GET /api/notifications/{id})
  static const String notificationsList = 'notifications';
  static const String notificationDetails = 'notifications/{id}';

  // Service types endpoints
  static const String serviceTypes = 'service-types';

  // Courier delivery endpoints
  static const String deliveryEstimate = 'services/delivery/estimate';
  static const String deliveryRequest = 'services/delivery/request';

  // Ride/Taxi endpoints
  static const String rideEstimate = 'services/ride/estimate';
  static const String rideRequest = 'services/ride/request';
  static const String rideAvailableVehicles = 'services/ride/available-vehicles';
  static const String userRidesActive = 'user/rides/active';
  static const String deliveryTrack = 'services/delivery/track/{id}';
  static const String userDeliveries = 'user/deliveries';
  static const String userDeliveryDetails = 'user/deliveries/{id}';
  static const String userDeliveriesActive = 'user/deliveries/active';

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
