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
///
/// Credentials may be persisted without enabling unlock (`saveCredentials`).
/// Enable is a separate opt-in (`enableBiometricLogin`).
class BiometricCredentialService {
  BiometricCredentialService._internal();
  static final BiometricCredentialService _instance =
      BiometricCredentialService._internal();
  factory BiometricCredentialService() => _instance;

  static const _schemaVersion = 1;
  static const _enabledKey = 'biometric_login_enabled';
  static const _credentialsKey = 'biometric_credentials_blob';
  static const _optedOutKey = 'biometric_user_opted_out';

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

  /// Face unlock available → face icon; otherwise fingerprint.
  Future<bool> prefersFaceIcon() async {
    final types = await getAvailableBiometrics();
    return types.contains(BiometricType.face);
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

  Future<bool> hasUserOptedOut() async {
    final value = await _storage.read(key: _optedOutKey);
    return value == 'true';
  }

  /// Credentials present regardless of enabled flag.
  Future<bool> hasCredentialBlob() async {
    final creds = await _readCredentialsInternal(validateDevice: true);
    return creds != null;
  }

  /// Enabled and credentials present (show biometric login control).
  Future<bool> hasEnabledSession() async {
    if (!await isBiometricLoginEnabled()) return false;
    return hasCredentialBlob();
  }

  /// Back-compat alias for [hasEnabledSession].
  Future<bool> hasStoredCredentials() => hasEnabledSession();

  /// Device supports biometrics, credentials saved, not enabled, not opted out.
  Future<bool> shouldOfferOptIn() async {
    if (!await isDeviceSupported()) return false;
    if (await isBiometricLoginEnabled()) return false;
    if (await hasUserOptedOut()) return false;
    if (!await hasCredentialBlob()) return false;
    return true;
  }

  /// Persist credentials without enabling biometric login.
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
  }

  /// Enable unlock; requires credentials already saved. Clears opt-out.
  /// Returns `false` if there is no credential blob.
  Future<bool> enableBiometricLogin() async {
    if (!await hasCredentialBlob()) return false;
    await _storage.write(key: _enabledKey, value: 'true');
    await _storage.delete(key: _optedOutKey);
    return true;
  }

  /// Disable unlock but keep credentials for easy re-enable.
  Future<void> optOut() async {
    await _storage.write(key: _enabledKey, value: 'false');
    await _storage.write(key: _optedOutKey, value: 'true');
  }

  /// Disable unlock; keep credentials. Prefer [optOut] for Settings off.
  Future<void> disableBiometricLogin() => optOut();

  /// Wipe credentials but keep opt-out (e.g. account switch).
  Future<void> clearSessionKeepOptOut() async {
    await _storage.delete(key: _credentialsKey);
    await _storage.write(key: _enabledKey, value: 'false');
  }

  /// Full wipe of biometric session and opt-out flag.
  Future<void> clearAll() async {
    await _storage.delete(key: _credentialsKey);
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _optedOutKey);
  }

  /// @Deprecated — use [optOut] or [clearAll]. Kept for call-site migration.
  Future<void> setBiometricLoginEnabled(bool enabled) async {
    if (enabled) {
      await enableBiometricLogin();
    } else {
      await optOut();
    }
  }

  Future<BiometricStoredCredentials?> readCredentials() async {
    if (!await isBiometricLoginEnabled()) return null;
    return _readCredentialsInternal(validateDevice: true);
  }

  /// Peek stored credentials without requiring enabled (for matching / persist).
  Future<BiometricStoredCredentials?> peekCredentials() {
    return _readCredentialsInternal(validateDevice: true);
  }

  Future<bool> matchesStoredLoginIdentifier(
    String attempted, {
    String? fieldType,
  }) async {
    final stored = await peekCredentials();
    if (stored == null) return false;

    final type = fieldType ?? stored.fieldType;
    if (type == 'email') {
      return attempted.trim().toLowerCase() ==
          stored.identifier.trim().toLowerCase();
    }

    final attemptedDigits = attempted.replaceAll(RegExp(r'\D'), '');
    final storedDigits = stored.identifier.replaceAll(RegExp(r'\D'), '');
    return attemptedDigits.isNotEmpty && attemptedDigits == storedDigits;
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
