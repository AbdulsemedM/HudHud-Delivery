import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hudhud_delivery/app/navigation/fcm_order_navigation.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/store_detail_screen.dart';

import 'data/models/hudhud_deep_link.dart';

export 'data/models/hudhud_deep_link.dart';

/// Handles HudHud app links (`/r/{code}`, `/o/{orderId}`, `/v/{vendorOwnerId}`,
/// `hudhud://vendor/{vendorOwnerId}`).
///
/// Vendor links use the founding-vendor QR id (`v<vendorOwnerUserId>`, see
/// [HudhudDeepLink.vendorId]). The Android intent-filter lists `/r/`, `/o/`
/// and `/v/`; iOS uses the `applinks:hudhuddelivery.com` entitlement (paths
/// come from the server's apple-app-site-association). The `hudhud://`
/// scheme is parsed but has no native registration yet.
///
/// Native config is in place (Android intent-filter with autoVerify and the
/// iOS `applinks:hudhuddelivery.com` entitlement), but no Dart deep-link
/// package is in pubspec.yaml, so incoming URIs are not yet delivered here.
///
/// TODO(deep-links): add `app_links` to pubspec.yaml, then in [start]:
/// ```dart
/// final appLinks = AppLinks();
/// final initial = await appLinks.getInitialLink();
/// if (initial != null) await handleUri(initial);
/// _sub = appLinks.uriLinkStream.listen(handleUri);
/// ```
/// Everything else (parsing, referral storage, order routing) is ready.
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  static const String _pendingReferralKey = 'growth_pending_referral_code';

  GlobalKey<NavigatorState>? _navigatorKey;

  /// Call once after the root navigator key exists.
  void start(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    // TODO(deep-links): subscribe to the platform link stream here (see class doc).
  }

  /// Entry point for a received link. Safe to call with any URI.
  Future<void> handleUri(Uri uri) async {
    final link = HudhudDeepLink.parse(uri);
    if (link == null) return;
    final code = link.referralCode;
    if (code != null) {
      // Stored until signup; the signup form prefills it.
      await savePendingReferralCode(code);
      return;
    }
    final orderId = link.orderId;
    if (orderId != null) {
      await _openOrder(orderId);
      return;
    }
    final vendorId = link.vendorId;
    if (vendorId != null) _openVendor(vendorId);
  }

  int? _pendingVendorId;

  /// Vendor link received before the navigator was ready; the dashboard
  /// opens it once shown.
  int? takePendingVendorId() {
    final id = _pendingVendorId;
    _pendingVendorId = null;
    return id;
  }

  /// Store pages are public, so no sign-in is needed.
  void _openVendor(int vendorId) {
    final nav = _navigatorKey?.currentState;
    if (nav == null || !nav.mounted) {
      _pendingVendorId = vendorId;
      return;
    }
    openVendorStore(nav.context, vendorId);
  }

  /// Opens the store screen for a vendor OWNER user id.
  static void openVendorStore(BuildContext context, int vendorId) {
    if (!context.mounted || vendorId <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (c) => StoreDetailScreen(
          storeName: c.l10n.growthStoreFallbackName,
          vendorId: vendorId,
        ),
      ),
    );
  }

  Future<void> _openOrder(int orderId) async {
    final nav = _navigatorKey?.currentState;
    final authed = await AuthService().isAuthenticated();
    if (nav == null || !authed || !nav.mounted) {
      // Opened by the dashboard once the user is signed in.
      PendingFcmOrderNavigation.setPending(orderId);
      return;
    }
    final ctx = nav.context;
    if (!ctx.mounted) return;
    pushOrderDetailsById(ctx, orderId: orderId);
  }

  static Future<void> savePendingReferralCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingReferralKey, code.trim().toUpperCase());
    } catch (_) {}
  }

  static Future<String?> getPendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_pendingReferralKey)?.trim();
      return (code == null || code.isEmpty) ? null : code;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearPendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingReferralKey);
    } catch (_) {}
  }
}
