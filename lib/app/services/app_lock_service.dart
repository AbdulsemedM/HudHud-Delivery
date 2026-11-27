import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hudhud_delivery/app/navigation/app_navigator.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';

/// Thrown by [AppLockService.requirePaymentConfirmation] when the owner does
/// not confirm a payment. Its message is already localized, so the payment
/// screens' normal error display shows it as is.
class PaymentNotConfirmedException implements Exception {
  const PaymentNotConfirmedException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The identifier a customer asked us to remember on the password screen.
/// Never a password.
class RememberedLogin {
  const RememberedLogin({required this.identifier, required this.fieldType});

  final String identifier;

  /// 'email' or 'phone'.
  final String fieldType;
}

/// Optional biometric app lock.
///
/// Replaces the old biometric *login*, which saved the customer's password on
/// the device and replayed it. Sign-in is now phone + one-time code, so there
/// is no password to replay, and a signed-in session already survives app
/// restarts. What a fingerprint is still good for is proving it is the owner
/// holding an already signed-in phone: when the lock is on, the app asks for
/// it on launch, after [relockAfter] in the background, and before wallet
/// payments ([confirmPayment]).
///
/// Nothing secret is stored here: only an on/off flag. The device PIN /
/// pattern is accepted as a fallback, so a failed fingerprint sensor never
/// locks anyone out of their account.
class AppLockService {
  AppLockService._internal({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ?? _defaultStorage,
        _localAuth = localAuth ?? LocalAuthentication();

  static AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;

  @visibleForTesting
  static void overrideForTesting({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  }) {
    _instance =
        AppLockService._internal(storage: storage, localAuth: localAuth);
  }

  /// Time in the background after which the app locks again.
  static const relockAfter = Duration(minutes: 2);

  static const _enabledKey = 'app_lock_enabled';
  static const _rememberIdentifierKey = 'remember_me_identifier';
  static const _rememberFieldTypeKey = 'remember_me_field_type';

  /// Keys of the removed biometric login. The blob held the customer's
  /// password in plain text (inside OS secure storage).
  static const _legacyKeys = [
    'biometric_credentials_blob',
    'biometric_login_enabled',
    'biometric_user_opted_out',
    'remember_me_enabled',
  ];

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  // --- Capability -----------------------------------------------------------

  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Face unlock available → face icon; otherwise fingerprint.
  Future<bool> prefersFaceIcon() async {
    if (kIsWeb) return false;
    try {
      final types = await _localAuth.getAvailableBiometrics();
      return types.contains(BiometricType.face);
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  bool _authenticating = false;

  /// True while a system fingerprint / face prompt is showing. The prompt
  /// sends the app to the background on some devices; the lock gate must
  /// not mistake that for the customer leaving the app.
  bool get isAuthenticating => _authenticating;

  /// Fingerprint / face, falling back to the device PIN or pattern.
  Future<bool> authenticate({required String reason}) async {
    if (kIsWeb) return false;
    _authenticating = true;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('[AppLockService] authenticate failed: ${e.code}');
      return false;
    } on MissingPluginException {
      return false;
    } finally {
      _authenticating = false;
    }
  }

  // --- Lock setting ---------------------------------------------------------

  Future<bool> isEnabled() async {
    try {
      return await _storage.read(key: _enabledKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await _storage.write(key: _enabledKey, value: 'true');
    } else {
      await _storage.delete(key: _enabledKey);
    }
  }

  /// One confirmation covers a payment and the automatic retries that
  /// follow it (a fresh idempotency key, a re-sent fine), so the customer is
  /// not asked twice for the same tap.
  static const confirmationWindow = Duration(seconds: 60);
  DateTime? _paymentConfirmedAt;

  /// Gate for a payment. `true` when the lock is off (nothing to confirm),
  /// when the device cannot authenticate any more (biometrics and PIN were
  /// removed in system settings: never strand a payment), when the owner
  /// confirmed within [confirmationWindow], or when the owner confirms now.
  Future<bool> confirmPayment({String? reason}) async {
    if (!await isEnabled()) return true;
    if (!await isDeviceSupported()) return true;
    final last = _paymentConfirmedAt;
    if (last != null && DateTime.now().difference(last) < confirmationWindow) {
      return true;
    }
    final ok = await authenticate(
      reason: reason ??
          _localized((l) => l.paymentConfirmReason, 'Confirm this payment'),
    );
    if (ok) _paymentConfirmedAt = DateTime.now();
    return ok;
  }

  /// [confirmPayment] for code without a [BuildContext] (repositories):
  /// throws [PaymentNotConfirmedException] when the owner does not confirm.
  Future<void> requirePaymentConfirmation() async {
    if (await confirmPayment()) return;
    throw PaymentNotConfirmedException(
      _localized((l) => l.paymentConfirmCancelled, 'Payment cancelled'),
    );
  }

  String _localized(
    String Function(AppLocalizations l10n) pick,
    String fallback,
  ) {
    final context = AppNavigator.key?.currentContext;
    final l10n = context == null ? null : AppLocalizations.of(context);
    return l10n == null ? fallback : pick(l10n);
  }

  // --- Remember me (identifier only) ----------------------------------------

  Future<RememberedLogin?> readRememberedLogin() async {
    try {
      final identifier = await _storage.read(key: _rememberIdentifierKey);
      if (identifier == null || identifier.isEmpty) return null;
      final fieldType =
          await _storage.read(key: _rememberFieldTypeKey) ?? 'phone';
      return RememberedLogin(identifier: identifier, fieldType: fieldType);
    } catch (_) {
      return null;
    }
  }

  Future<void> rememberLogin({
    required String identifier,
    required String fieldType,
  }) async {
    await _storage.write(key: _rememberIdentifierKey, value: identifier);
    await _storage.write(key: _rememberFieldTypeKey, value: fieldType);
  }

  Future<void> forgetLogin() async {
    await _storage.delete(key: _rememberIdentifierKey);
    await _storage.delete(key: _rememberFieldTypeKey);
  }

  // --- Lifecycle ------------------------------------------------------------

  /// Called on sign-out: the next person to sign in on this phone chooses
  /// for themselves.
  Future<void> onSignedOut() async {
    _paymentConfirmedAt = null;
    await setEnabled(false);
  }

  /// One-time cleanup of the removed biometric login, which kept the
  /// password on the device. Safe to call on every start.
  Future<void> purgeLegacyBiometricLogin() async {
    for (final key in _legacyKeys) {
      try {
        await _storage.delete(key: key);
      } catch (_) {}
    }
  }
}
