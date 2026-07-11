import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Login credentials restored after device check and biometric gate.
class BiometricStoredCredentials {
  const BiometricStoredCredentials({
    required this.identifier,
    required this.password,
    required this.fieldType,
  });

  final String identifier;
  final String password;
  final String fieldType;
}

/// Stores email/phone login credentials in OS secure storage, bound to this device.
/// Biometric verification is required in app UI before reading credentials.
class BiometricCredentialService {
  BiometricCredentialService._internal();
  static final BiometricCredentialService _instance =
      BiometricCredentialService._internal();
  factory BiometricCredentialService() => _instance;

  static const _schemaVersion = 1;
  static const _enabledKey = 'biometric_login_enabled';
  static const _credentialsKey = 'biometric_credentials_blob';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isBiometricLoginEnabled() async {
    final value = await _storage.read(key: _enabledKey);
    return value == 'true';
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    if (enabled) {
      await _storage.write(key: _enabledKey, value: 'true');
    } else {
      await clearCredentials();
      await _storage.delete(key: _enabledKey);
    }
  }

  Future<bool> hasStoredCredentials() async {
    if (!await isBiometricLoginEnabled()) return false;
    final creds = await _readCredentialsInternal(validateDevice: true);
    return creds != null;
  }

  Future<void> saveCredentials({
    required String identifier,
    required String password,
    required String fieldType,
  }) async {
    final fingerprint = await _deviceFingerprint();
    final payload = jsonEncode({
      'schemaVersion': _schemaVersion,
      'identifier': identifier,
      'password': password,
      'fieldType': fieldType,
      'deviceFingerprint': fingerprint,
    });
    await _storage.write(key: _credentialsKey, value: payload);
    await _storage.write(key: _enabledKey, value: 'true');
  }

  Future<BiometricStoredCredentials?> readCredentials() async {
    if (!await isBiometricLoginEnabled()) return null;
    return _readCredentialsInternal(validateDevice: true);
  }

  Future<BiometricStoredCredentials?> _readCredentialsInternal({
    required bool validateDevice,
  }) async {
    try {
      final raw = await _storage.read(key: _credentialsKey);
      if (raw == null || raw.isEmpty) return null;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final storedFingerprint = map['deviceFingerprint'] as String?;
      if (validateDevice) {
        final current = await _deviceFingerprint();
        if (storedFingerprint == null || storedFingerprint != current) {
          await clearCredentials();
          return null;
        }
      }

      final identifier = map['identifier'] as String?;
      final password = map['password'] as String?;
      final fieldType = map['fieldType'] as String?;
      if (identifier == null ||
          password == null ||
          fieldType == null ||
          identifier.isEmpty ||
          password.isEmpty) {
        await clearCredentials();
        return null;
      }

      return BiometricStoredCredentials(
        identifier: identifier,
        password: password,
        fieldType: fieldType,
      );
    } catch (e) {
      debugPrint('[BiometricCredentialService] read failed: $e');
      await clearCredentials();
      return null;
    }
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _credentialsKey);
  }

  Future<String> _deviceFingerprint() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return 'android:${android.id}';
      }
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        final vendorId = ios.identifierForVendor;
        if (vendorId != null && vendorId.isNotEmpty) {
          return 'ios:$vendorId';
        }
      }
    } catch (e) {
      debugPrint('[BiometricCredentialService] device id failed: $e');
    }
    return 'unknown:${Platform.operatingSystem}';
  }
}
