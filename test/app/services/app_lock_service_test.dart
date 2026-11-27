import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/services/app_lock_service.dart';
import 'package:local_auth/local_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_platform_interface/types/auth_messages.dart';

class _FakeLocalAuth extends LocalAuthentication {
  _FakeLocalAuth({this.supported = true});

  bool supported;
  bool result = true;
  int prompts = 0;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async =>
      [BiometricType.fingerprint];

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    prompts++;
    return result;
  }
}

void main() {
  late _FakeLocalAuth auth;
  late AppLockService service;
  const storage = FlutterSecureStorage();

  void setUpWith(Map<String, String> stored, {bool supported = true}) {
    FlutterSecureStorage.setMockInitialValues(Map.of(stored));
    auth = _FakeLocalAuth(supported: supported);
    AppLockService.overrideForTesting(storage: storage, localAuth: auth);
    service = AppLockService();
  }

  test('a payment needs no confirmation while the lock is off', () async {
    setUpWith({});
    expect(await service.confirmPayment(reason: 'pay'), isTrue);
    expect(auth.prompts, 0);
  });

  test('with the lock on a payment asks, and a declined prompt blocks it',
      () async {
    setUpWith({'app_lock_enabled': 'true'});
    auth.result = false;
    expect(await service.confirmPayment(reason: 'pay'), isFalse);
    expect(auth.prompts, 1);
    await expectLater(
      service.requirePaymentConfirmation(),
      throwsA(isA<PaymentNotConfirmedException>()),
    );
  });

  test('one confirmation covers the automatic retries that follow', () async {
    setUpWith({'app_lock_enabled': 'true'});
    expect(await service.confirmPayment(reason: 'pay'), isTrue);
    expect(await service.confirmPayment(reason: 'retry'), isTrue);
    await service.requirePaymentConfirmation();
    expect(auth.prompts, 1);
  });

  test('a device that can no longer authenticate never strands a payment',
      () async {
    setUpWith({'app_lock_enabled': 'true'}, supported: false);
    expect(await service.confirmPayment(reason: 'pay'), isTrue);
    expect(auth.prompts, 0);
  });

  test('signing out turns the lock off', () async {
    setUpWith({'app_lock_enabled': 'true'});
    await service.onSignedOut();
    expect(await service.isEnabled(), isFalse);
  });

  test('the old biometric login data, including the password, is wiped',
      () async {
    setUpWith({
      'biometric_credentials_blob': '{"password":"secret"}',
      'biometric_login_enabled': 'true',
      'biometric_user_opted_out': 'false',
      'remember_me_enabled': 'true',
      'app_lock_enabled': 'true',
    });
    await service.purgeLegacyBiometricLogin();
    final all = await storage.readAll();
    expect(all.keys, ['app_lock_enabled']);
  });

  test('remember-me keeps the identifier and never a password', () async {
    setUpWith({});
    await service.rememberLogin(
        identifier: '+251911000111', fieldType: 'phone');
    final remembered = await service.readRememberedLogin();
    expect(remembered?.identifier, '+251911000111');
    expect(remembered?.fieldType, 'phone');
    final values = (await storage.readAll()).values.join(' ');
    expect(values.toLowerCase(), isNot(contains('password')));

    await service.forgetLogin();
    expect(await service.readRememberedLogin(), isNull);
  });
}
