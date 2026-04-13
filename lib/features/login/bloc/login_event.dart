part of 'login_bloc.dart';

@immutable
sealed class LoginEvent {}

class LoginFormSubmitted extends LoginEvent {
  final String emailOrPhone;
  final String password;
  final String fieldType; // 'email' or 'phone'
  LoginFormSubmitted(this.emailOrPhone, this.password, this.fieldType);
}

class GuestLoginRequested extends LoginEvent {}

class GoogleLoginRequested extends LoginEvent {}
