part of 'signup_bloc.dart';

@immutable
sealed class SignupEvent {}

final class SignupFormSubmitted extends SignupEvent { 
  final String name;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  SignupFormSubmitted(
    this.name,
    this.email,
    this.phone,
    this.password,
    this.confirmPassword,
  );
}
