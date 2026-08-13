import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hudhud_delivery/app/notifications/notification_events.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/fcm_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_data_provider.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_repository.dart';

/// Manages Firebase topic subscriptions for the customer app.
class FcmTopicService {
  FcmTopicService._();
  static final FcmTopicService _instance = FcmTopicService._();
  factory FcmTopicService() => _instance;

  static const _prefsKey = 'fcm_subscribed_topics';

  final Set<String> _subscribedTopics = {};

  /// Subscribe to customer topics after login or session restore.
  Future<void> subscribeForCurrentUser({bool marketingEnabled = false}) async {
    try {
      final auth = AuthService();
      await auth.initialize();
      final userId = auth.currentUser?.id;
      if (userId == null) return;

      final topics = <String>{
        'customer_$userId',
        'system_updates',
      };

      final cityCode = await _resolveCityCode();
      if (cityCode.isNotEmpty) {
        topics.add('city_$cityCode');
        topics.add('customers_$cityCode');
      }

      if (marketingEnabled) {
        topics.add('promotions');
      }

      for (final topic in topics) {
        if (_subscribedTopics.contains(topic)) continue;
        await FcmService().subscribeToTopic(topic);
        _subscribedTopics.add(topic);
      }

      await _persistTopics();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FcmTopicService.subscribeForCurrentUser failed: $e');
      }
    }
  }

  Future<String> _resolveCityCode() async {
    try {
      final repo = AddressesRepository(
        addressesDataProvider: AddressesDataProvider(
          apiService: ApiService.instance,
        ),
      );
      final address = await repo.getDefaultAddress();
      if (address != null && address.city.isNotEmpty) {
        return normalizeCityCode(address.city);
      }
    } catch (_) {}
    return '';
  }

  /// Unsubscribe from all tracked topics (call on logout).
  Future<void> unsubscribeAll() async {
    await _loadPersistedTopics();
    for (final topic in _subscribedTopics.toList()) {
      try {
        await FcmService().unsubscribeFromTopic(topic);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('FcmTopicService.unsubscribe $topic failed: $e');
        }
      }
    }
    _subscribedTopics.clear();
    await _persistTopics();
  }

  Future<void> _loadPersistedTopics() async {
    if (_subscribedTopics.isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_prefsKey);
      if (stored != null) _subscribedTopics.addAll(stored);
    } catch (_) {}
  }

  Future<void> _persistTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _subscribedTopics.toList());
    } catch (_) {}
  }
}
