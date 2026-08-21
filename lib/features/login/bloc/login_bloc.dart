import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/biometric_credential_service.dart';
import 'package:hudhud_delivery/app/services/google_auth_helper.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import '../data/repository/login_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository loginRepository;
  LoginBloc(this.loginRepository) : super(LoginInitial()) {
    on<LoginFormSubmitted>((event, emit) async {
      emit(LoginLoading(LoginAction.credentials));
      try {
        await loginRepository.login(
          event.emailOrPhone,
          event.password,
          event.fieldType,
        );
        emit(LoginSuccess(LoginAction.credentials));
      } catch (e) {
        emit(_failureFrom(e));
      }
    });
    on<GuestLoginRequested>((event, emit) async {
      emit(LoginLoading(LoginAction.guest));
      try {
        await AuthService().clearAllData();
        await GuestBrowseService().enterGuestBrowseMode();
        emit(LoginSuccess(LoginAction.guest));
      } catch (e) {
        emit(_failureFrom(e));
      }
    });
    on<GoogleLoginRequested>((event, emit) async {
      emit(LoginLoading(LoginAction.google));
      try {
        await loginRepository.googleLogin();
        emit(LoginSuccess(LoginAction.google));
      } on GoogleSignInUserCancelled {
        emit(LoginInitial());
      } catch (e, st) {
        debugPrint('[GoogleSignIn] LoginBloc: $e');
        debugPrint('$st');
        emit(_failureFrom(e));
      }
    });
    on<BiometricLoginRequested>((event, emit) async {
      final biometricService = BiometricCredentialService();
      final authenticated = await biometricService.authenticate(
        localizedReason: event.authReason,
      );
      if (!authenticated) {
        emit(LoginFailure(event.authFailedMessage));
        return;
      }

      final credentials = await biometricService.readCredentials();
      if (credentials == null) {
        emit(LoginFailure(event.noCredentialsMessage));
        return;
      }

      emit(LoginLoading(LoginAction.biometric));
      try {
        await loginRepository.login(
          credentials.identifier,
          credentials.password,
          credentials.fieldType,
        );
        emit(LoginSuccess(LoginAction.biometric));
      } catch (e) {
        final failure = _failureFrom(e);
        if (_isInvalidCredentialsError(failure.errorMessage)) {
          await biometricService.clearAll();
        }
        emit(failure);
      }
    });
  }

  LoginFailure _failureFrom(Object e) {
    if (e is LoginFailureException) {
      return LoginFailure(
        e.message,
        attemptsRemaining: e.attemptsRemaining,
        retryAfterSeconds: e.retryAfterSeconds,
        isAccountLocked: e.isAccountLocked,
      );
    }
    final text = e.toString();
    return LoginFailure(
      text.startsWith('Exception: ') ? text.substring(11) : text,
    );
  }

  bool _isInvalidCredentialsError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('invalid') &&
        (lower.contains('credential') ||
            lower.contains('password') ||
            lower.contains('email') ||
            lower.contains('phone'));
  }
}
