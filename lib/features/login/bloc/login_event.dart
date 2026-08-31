part of 'login_bloc.dart';

@immutable
sealed class LoginEvent {}

class LoginFormSubmitted extends LoginEvent {
  final String emailOrPhone;
  final String password;
  final String fieldType; // 'email' or 'phone'
  final bool rememberMe;
  LoginFormSubmitted(
    this.emailOrPhone,
    this.password,
    this.fieldType, {
    this.rememberMe = false,
  });
}

class GoogleLoginRequested extends LoginEvent {}

class BiometricLoginRequested extends LoginEvent {
  final String authReason;
  final String noCredentialsMessage;
  final String authFailedMessage;

  BiometricLoginRequested({
    required this.authReason,
    required this.noCredentialsMessage,
    required this.authFailedMessage,
  });
}
