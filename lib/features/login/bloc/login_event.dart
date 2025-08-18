part of 'login_bloc.dart';

@immutable
sealed class LoginEvent {}

class LoginFormSubmitted extends LoginEvent {
  final String email;
  final String password;
  LoginFormSubmitted(this.email, this.password);
}
