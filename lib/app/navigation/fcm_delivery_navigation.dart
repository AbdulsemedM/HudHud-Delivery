import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:hudhud_delivery/app/notifications/notification_events.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/confirm_receipt_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/delivery_details_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/delivery_tracking_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/rate_delivery_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/verify_delivery_otp_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/active_delivery_card.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_notification.dart';

/// Tracks the latest known delivery status per delivery for stale-push suppression.
class DeliveryNotificationStatusCache {
  DeliveryNotificationStatusCache._();

  static final Map<int, String> _latestStatusByDelivery = {};

  static String? latestStatusFor(int deliveryId) =>
      _latestStatusByDelivery[deliveryId];

  static void recordStatus(int deliveryId, String? status) {
    final normalized = normalizeDeliveryStatus(status);
    if (normalized.isEmpty) return;

    final current = _latestStatusByDelivery[deliveryId];
    if (current == null ||
        deliveryStatusRank(normalized) >= deliveryStatusRank(current)) {
      _latestStatusByDelivery[deliveryId] = normalized;
    }
  }

  static bool shouldIgnorePayload(Map<String, String> data) {
    final deliveryId = parseDeliveryIdFromPayload(data);
    if (deliveryId == null) return false;

    final incoming = parseDeliveryStatusFromPayload(data);
    if (incoming == null) return false;

    final current = _latestStatusByDelivery[deliveryId];
    if (current == null) {
      recordStatus(deliveryId, incoming);
      return false;
    }

    if (isStaleDeliveryStatus(incoming, current)) {
      return true;
    }

    recordStatus(deliveryId, incoming);
    return false;
  }
}

CourierRepository _courierRepository() => CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );

LatLng? _parseLatLng(Map<String, dynamic> delivery, String latKey, String lngKey) {
  return parseDeliveryLatLng(delivery[latKey], delivery[lngKey]);
}

Future<Map<String, dynamic>?> _fetchDeliveryDetails(int deliveryId) async {
  final result = await _courierRepository().getUserDeliveryDetails(deliveryId);
  if (result['success'] == true) {
    final data = result['data'];
    if (data is Map<String, dynamic>) {
      DeliveryNotificationStatusCache.recordStatus(
        deliveryId,
        resolveDeliveryStatusFromMap(data),
      );
      return data;
    }
  }
  return null;
}

String? resolveDeliveryStatusFromMap(Map<String, dynamic> delivery) {
  final primary = delivery['status']?.toString().trim();
  if (primary != null && primary.isNotEmpty) return primary;
  final current = delivery['current_status']?.toString().trim();
  if (current != null && current.isNotEmpty) return current;
  return null;
}

Future<void> openDeliveryTrackingById(
  BuildContext context, {
  required int deliveryId,
}) async {
  if (!context.mounted) return;

  final delivery = await _fetchDeliveryDetails(deliveryId);
  if (!context.mounted) return;

  if (delivery == null) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeliveryDetailsScreen(deliveryId: deliveryId),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _trackingScreenFromDelivery(delivery),
    ),
  );
}

DeliveryTrackingScreen _trackingScreenFromDelivery(
  Map<String, dynamic> delivery,
) {
  final deliveryId = delivery['id'] is int
      ? delivery['id'] as int
      : int.tryParse(delivery['id']?.toString() ?? '');

  return DeliveryTrackingScreen(
    deliveryId: deliveryId,
    pickupLocation: delivery['pickup_location']?.toString() ?? '',
    deliveryLocation: delivery['dropoff_location']?.toString() ?? '',
    pickupPosition: _parseLatLng(delivery, 'pickup_latitude', 'pickup_longitude'),
    deliveryPosition: _parseLatLng(delivery, 'dropoff_latitude', 'dropoff_longitude'),
    selectedVehicle: delivery['vehicle_type']?.toString() ?? 'motorbike',
    itemType: delivery['package_type']?.toString() ?? '',
    quantity: delivery['package_weight']?.toString() ?? '1',
    whoPays: 'me',
    paymentType: delivery['payment_method']?.toString() ?? 'cash',
    recipientName: delivery['receiver_name']?.toString() ?? '',
    recipientPhone: delivery['receiver_phone']?.toString() ?? '',
  );
}

Future<void> openVerifyDeliveryOtpFromPayload(
  BuildContext context, {
  required Map<String, String> data,
  required int deliveryId,
}) async {
  if (!context.mounted) return;

  final delivery = await _fetchDeliveryDetails(deliveryId);
  if (!context.mounted) return;

  if (delivery != null &&
      isDeliveryTerminalStatus(resolveDeliveryStatusFromMap(delivery))) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _trackingScreenFromDelivery(delivery),
      ),
    );
    return;
  }

  final cachedStatus = DeliveryNotificationStatusCache.latestStatusFor(
    deliveryId,
  );
  if (isDeliveryTerminalStatus(cachedStatus)) {
    await openDeliveryTrackingById(context, deliveryId: deliveryId);
    return;
  }

  final otp = data['otp']?.trim();
  final expiresRaw = data['expires_in_minutes'] ?? data['expiresInMinutes'];
  final expiresOnVerificationRaw = data['expires_on_delivery_verification'] ??
      data['expiresOnDeliveryVerification'];
  final expiresOnDeliveryVerification = expiresOnVerificationRaw == 'true' ||
      expiresOnVerificationRaw == '1' ||
      (expiresRaw == null || expiresRaw.trim().isEmpty);
  final trackingNumber =
      data['tracking_number'] ?? data['trackingNumber'] ?? delivery?['tracking_number']?.toString();

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => VerifyDeliveryOtpScreen(
        deliveryId: deliveryId,
        otp: otp,
        expiresOnDeliveryVerification: expiresOnDeliveryVerification,
        trackingNumber: trackingNumber,
      ),
    ),
  );
}

Future<void> openConfirmReceiptById(
  BuildContext context, {
  required int deliveryId,
}) async {
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ConfirmReceiptScreen(deliveryId: deliveryId),
    ),
  );
}

Future<void> openRateDeliveryById(
  BuildContext context, {
  required int deliveryId,
}) async {
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RateDeliveryScreen(deliveryId: deliveryId),
    ),
  );
}

Future<bool> routeDeliveryNotificationPayload(
  BuildContext context,
  Map<String, String> data,
) async {
  if (DeliveryNotificationStatusCache.shouldIgnorePayload(data)) {
    return true;
  }

  final deliveryId = parseDeliveryIdFromPayload(data);
  if (deliveryId == null) return false;

  final screen = data['screen']?.trim().toLowerCase();
  final status = parseDeliveryStatusFromPayload(data);

  if (isOtpRequiredPayload(data) || screen == NotificationScreens.verifyDelivery) {
    final cachedStatus = DeliveryNotificationStatusCache.latestStatusFor(
      deliveryId,
    );
    if (isDeliveryTerminalStatus(cachedStatus)) {
      await openDeliveryTrackingById(context, deliveryId: deliveryId);
      return true;
    }
    await openVerifyDeliveryOtpFromPayload(
      context,
      data: data,
      deliveryId: deliveryId,
    );
    return true;
  }

  switch (screen) {
    case NotificationScreens.deliveryTracking:
      await openDeliveryTrackingById(context, deliveryId: deliveryId);
      return true;
    case NotificationScreens.confirmReceipt:
      await openConfirmReceiptById(context, deliveryId: deliveryId);
      return true;
    case NotificationScreens.rateDelivery:
      await openRateDeliveryById(context, deliveryId: deliveryId);
      return true;
    case NotificationScreens.verifyDelivery:
      await openVerifyDeliveryOtpFromPayload(
        context,
        data: data,
        deliveryId: deliveryId,
      );
      return true;
  }

  if (status == NotificationEvents.delivered ||
      status == NotificationEvents.deliveryCompleted) {
    if (!context.mounted) return true;
    if (screen == NotificationScreens.rateDelivery) {
      await openRateDeliveryById(context, deliveryId: deliveryId);
    } else {
      await openConfirmReceiptById(context, deliveryId: deliveryId);
    }
    return true;
  }

  if (isDeliveryLifecycleStatus(status) ||
      isPackageDeliveryEvent(data['event'])) {
    if (!context.mounted) return true;
    await openDeliveryTrackingById(context, deliveryId: deliveryId);
    return true;
  }

  return false;
}
