part of 'login_bloc.dart';

enum LoginAction { credentials, guest, google, biometric }

@immutable
sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {
  final LoginAction action;

  LoginLoading(this.action);
}

final class LoginSuccess extends LoginState {
  final LoginAction action;

  LoginSuccess(this.action);
}

final class LoginFailure extends LoginState {
  final String errorMessage;
  final int? attemptsRemaining;
  final int? retryAfterSeconds;
  final bool isAccountLocked;

  LoginFailure(
    this.errorMessage, {
    this.attemptsRemaining,
    this.retryAfterSeconds,
    this.isAccountLocked = false,
  });
}

extension LoginStateLoading on LoginState {
  bool get isAnyLoginLoading => this is LoginLoading;

  bool isLoginLoading(LoginAction action) =>
      this is LoginLoading && (this as LoginLoading).action == action;
}
