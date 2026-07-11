part of 'login_bloc.dart';

enum LoginAction { credentials, guest, google, biometric }

@immutable
sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {
  final LoginAction action;

  LoginLoading(this.action);
}

final class LoginSuccess extends LoginState {}

final class LoginFailure extends LoginState {
  final String errorMessage;
  LoginFailure(this.errorMessage);
}

extension LoginStateLoading on LoginState {
  bool get isAnyLoginLoading => this is LoginLoading;

  bool isLoginLoading(LoginAction action) =>
      this is LoginLoading && (this as LoginLoading).action == action;
}
