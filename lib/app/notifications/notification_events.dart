/// Customer-relevant FCM notification event and screen identifiers.
///
/// Event names from the server may arrive as `ORDER_CREATED` or `order_created`;
/// always match using [normalizeEvent].
class NotificationEvents {
  NotificationEvents._();

  // Customer order lifecycle
  static const orderCreated = 'order_created';
  static const searchingForRider = 'searching_for_rider';
  static const riderAssigned = 'rider_assigned';
  static const riderEnRoutePickup = 'rider_en_route_pickup';
  static const riderArrivedPickup = 'rider_arrived_pickup';
  static const packagePickedUp = 'package_picked_up';
  static const deliveryStarted = 'delivery_started';
  static const riderNearby = 'rider_nearby';
  static const riderArrivedDestination = 'rider_arrived_destination';
  static const deliveryCompleted = 'delivery_completed';
  static const deliveryCancelled = 'delivery_cancelled';
  static const deliveryFailed = 'delivery_failed';
  static const riderReassigned = 'rider_reassigned';
  static const scheduledDeliveryReminder = 'scheduled_delivery_reminder';
  static const deliveryDelayed = 'delivery_delayed';
  static const etaUpdated = 'eta_updated';

  // Security / OTP
  static const registrationOtp = 'registration_otp';
  static const loginOtp = 'login_otp';
  static const forgotPasswordOtp = 'forgot_password_otp';
  static const phoneVerification = 'phone_verification';
  static const newDeviceLogin = 'new_device_login';
  static const passwordChanged = 'password_changed';
  static const pinChanged = 'pin_changed';
  static const suspiciousActivity = 'suspicious_activity';
  static const accountLocked = 'account_locked';

  static const customerOrderEvents = {
    orderCreated,
    searchingForRider,
    riderAssigned,
    riderEnRoutePickup,
    riderArrivedPickup,
    packagePickedUp,
    deliveryStarted,
    riderNearby,
    riderArrivedDestination,
    deliveryCompleted,
    deliveryCancelled,
    deliveryFailed,
    riderReassigned,
    scheduledDeliveryReminder,
    deliveryDelayed,
    etaUpdated,
  };

  static const securityEvents = {
    registrationOtp,
    loginOtp,
    forgotPasswordOtp,
    phoneVerification,
    newDeviceLogin,
    passwordChanged,
    pinChanged,
    suspiciousActivity,
    accountLocked,
  };

  static const otpNavigationEvents = {
    registrationOtp,
    loginOtp,
    forgotPasswordOtp,
  };
}

class NotificationScreens {
  NotificationScreens._();

  static const orderDetails = 'order_details';
  static const orders = 'orders';
  static const home = 'home';
  static const settings = 'settings';
}

/// Normalises event names to lowercase snake_case for comparison.
String normalizeEvent(String? event) {
  if (event == null || event.isEmpty) return '';
  return event.trim().toLowerCase().replaceAll('-', '_');
}

/// Normalises a city name to a Firebase topic city code (`addis_ababa`).
String normalizeCityCode(String? city) {
  if (city == null || city.trim().isEmpty) return '';
  return city
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

/// Extracts a numeric order id from FCM data payload keys.
int? parseOrderIdFromPayload(Map<String, String> data) {
  for (final key in const ['order_id', 'orderId', 'id']) {
    if (data.containsKey(key)) {
      final n = int.tryParse(data[key]!);
      if (n != null) return n;
    }
  }
  return null;
}

bool isCustomerOrderEvent(String? event) {
  final normalized = normalizeEvent(event);
  if (normalized.isEmpty) return false;
  return NotificationEvents.customerOrderEvents.contains(normalized);
}

bool isSecurityEvent(String? event) {
  final normalized = normalizeEvent(event);
  if (normalized.isEmpty) return false;
  return NotificationEvents.securityEvents.contains(normalized);
}

bool isOtpNavigationEvent(String? event) {
  final normalized = normalizeEvent(event);
  if (normalized.isEmpty) return false;
  return NotificationEvents.otpNavigationEvents.contains(normalized);
}
