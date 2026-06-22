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

  /// POST — returns same shape as [login] (token, user, optional refresh_token).
  /// Coordinate path with backend if it differs.
  static const String guest = '$auth/guest';
  /// POST body: `id_token`, optional `user_type`, optional `device_token`.
  static const String googleLogin = '$auth/google-login';
  /// Password reset OTP flow (unauthenticated): POST `/api/password/...`
  static const String passwordResetOtp = 'password/reset-otp';
  static const String passwordVerifyOtp = 'password/verify-otp';
  static const String passwordResendOtp = 'password/resend-otp';
  static const String passwordResetWithToken = 'password/reset-with-token';

  // FCM endpoints
  static const String fcmToken = 'fcm/token';

  // User endpoints
  static const String users = '/users';
  static const String profile =
      'profile'; // GET /api/profile returns user object at root
  /// POST multipart: name, email, phone, optional avatar file.
  static const String updateProfile = 'update-profile';
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
  static const String products = 'products';
  static const String productDetails = 'products/{id}';

  // Vendors endpoints
  static const String vendors = 'vendors';

  // Public (unauthenticated) catalog endpoints
  static const String publicProducts = 'public/products';
  static const String publicProductDetails = 'public/products/{id}';
  static const String publicProductsFeatured = 'public/products/featured';
  static const String publicSearch = 'public/search';
  static const String publicCategories = 'public/categories';
  static const String publicCategoryProducts = 'public/categories/{id}/products';
  static const String publicVendors = 'public/vendors';
  static const String publicVendorProducts = 'public/vendors/{id}/products';
  static const String publicBranches = 'public/branches';
  static const String publicBranchesNearby = 'public/branches/nearby';

  // Notifications endpoints (GET /api/notifications, GET /api/notifications/{id})
  static const String notificationsList = 'notifications';
  static const String notificationDetails = 'notifications/{id}';

  // Service types endpoints
  static const String serviceTypes = 'service-types';
  static const String validateCoupon = 'coupons/validate';

  // Courier delivery endpoints
  static const String deliveryEstimate = 'services/delivery/estimate';
  static const String deliveryRequest = 'services/delivery/request';

  // Ride/Taxi endpoints
  static const String rideEstimate = 'services/ride/estimate';
  static const String rideRequest = 'services/ride/request';
  static const String rideAvailableVehicles =
      'services/ride/available-vehicles';
  static const String userRidesActive = 'user/rides/active';
  static const String deliveryTrack = 'services/delivery/track/{id}';
  static const String userDeliveries = 'user/deliveries';
  static const String userDeliveryDetails = 'user/deliveries/{id}';
  static const String userDeliveriesActive = 'user/deliveries/active';

  // Handyman / Service requests
  static const String customerServiceRequests = 'customer/services/requests';
  static const String customerServiceRequestQuotes =
      'customer/services/requests/{id}/quotes';
  static const String customerServiceRequestQuoteAccept =
      'customer/services/requests/{id}/quotes/{quoteId}/accept';
  static const String customerServiceRequestQuoteReject =
      'customer/services/requests/{id}/quotes/{quoteId}/reject';
  static const String customerServiceRequestCancel =
      'customer/services/requests/{id}/cancel';
  static const String customerHandymen = 'customer/services/handymen/{id}';
  static const String customerServiceRequestRate =
      'customer/service-requests/{id}/rate';

  // Chat endpoints
  static const String chatConversations = 'chat/conversations';
  static const String chatConversationDetails = 'chat/conversations/{id}';
  static const String chatConversationMessages =
      'chat/conversations/{id}/messages';
  static const String chatConversationRead = 'chat/conversations/{id}/read';
  static const String chatUnreadCount = 'chat/unread-count';
  static const String chatOrder = 'chat/order/{orderId}';
  static const String chatSupport = 'chat/support';
  static const String chatRide = 'chat/ride/{rideId}';
  static const String chatMessage = 'chat/messages/{id}';

  // Package delivery chat endpoints
  static const String packageDeliveryUnreadCount =
      'package-delivery/unread-count';
  static const String packageDeliveryConversations =
      'package-delivery/conversations';
  static const String packageDeliveryConversation =
      'package-delivery/{deliveryId}/conversation';
  static const String packageDeliveryRead =
      'package-delivery/{deliveryId}/read';
  static const String packageDeliveryMessage =
      'package-delivery/{deliveryId}/message';

  // SOS endpoints
  static const String sosTrigger = 'sos/trigger';
  static const String sosHistory = 'sos/history';
  static const String sosContacts = 'sos/contacts';
  static const String sosContactDetails = 'sos/contacts/{id}';

  // Wishlist endpoints
  static const String wishlist = 'wishlist';
  static const String wishlistAdd = 'wishlist/add';
  static const String wishlistItem = 'wishlist/{id}';
  static const String wishlistItemNotes = 'wishlist/{id}/notes';
  static const String wishlistBulkRemove = 'wishlist/bulk-remove';
  static const String wishlistShare = 'wishlist/share';
  static const String wishlistPriceDrops = 'wishlist/price-drops';

  // Tips endpoints
  static const String tipsRates = 'tips/rates';
  static const String tipsCalculate = 'tips/calculate';
  static const String tipsAdd = 'tips/add';
  static const String tipsHistory = 'tips/history';

  // Address endpoints
  static const String addresses = 'addresses';
  static const String addressDetails = 'addresses/{id}';
  static const String addressSetDefault = 'addresses/{id}/set-default';
  static const String addressesDefault = 'addresses-default';
  static const String addressesBulkDelete = 'addresses/bulk/delete';

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
