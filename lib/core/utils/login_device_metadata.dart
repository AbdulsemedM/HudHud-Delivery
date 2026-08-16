import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/services/fcm_service.dart';

/// Optional device / app fields for `POST /api/login`.
class LoginDeviceMetadata {
  const LoginDeviceMetadata({
    this.fcmToken,
    this.deviceType,
    this.deviceId,
    this.appVersion,
    this.osVersion,
  });

  final String? fcmToken;
  final String? deviceType;
  final String? deviceId;
  final String? appVersion;
  final String? osVersion;

  /// Best-effort collection; never throws.
  static Future<LoginDeviceMetadata> collect() async {
    String? fcmToken;
    String? deviceType;
    String? deviceId;
    String? appVersion;
    String? osVersion;

    try {
      final token = await FcmService().getToken();
      if (token != null && token.isNotEmpty) fcmToken = token;
    } catch (e) {
      if (kDebugMode) debugPrint('LoginDeviceMetadata: FCM token failed: $e');
    }

    try {
      deviceType =
          Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : null);
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        deviceId = info.id;
        osVersion = 'Android ${info.version.release}';
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        deviceId = info.identifierForVendor;
        osVersion = 'iOS ${info.systemVersion}';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('LoginDeviceMetadata: device info failed: $e');
    }

    try {
      final package = await PackageInfo.fromPlatform();
      appVersion = package.version;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LoginDeviceMetadata: package info failed: $e');
      }
    }

    return LoginDeviceMetadata(
      fcmToken: fcmToken,
      deviceType: deviceType,
      deviceId: deviceId,
      appVersion: appVersion,
      osVersion: osVersion,
    );
  }

  void applyTo(Map<String, dynamic> body) {
    if (fcmToken != null && fcmToken!.isNotEmpty) {
      body['fcm_token'] = fcmToken;
    }
    if (deviceType != null && deviceType!.isNotEmpty) {
      body['device_type'] = deviceType;
    }
    if (deviceId != null && deviceId!.isNotEmpty) {
      body['device_id'] = deviceId;
    }
    if (appVersion != null && appVersion!.isNotEmpty) {
      body['app_version'] = appVersion;
    }
    if (osVersion != null && osVersion!.isNotEmpty) {
      body['os_version'] = osVersion;
    }
  }
}
