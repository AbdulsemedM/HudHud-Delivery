import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hudhud_delivery/app/services/google_auth_helper.dart';
import '../data/repository/login_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository loginRepository;
  LoginBloc(this.loginRepository) : super(LoginInitial()) {
    on<LoginFormSubmitted>((event, emit) async {
      emit(LoginLoading());
      try {
        await loginRepository.login(
          event.emailOrPhone,
          event.password,
          event.fieldType,
        );
        emit(LoginSuccess());
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });
    on<GuestLoginRequested>((event, emit) async {
      emit(LoginLoading());
      try {
        await loginRepository.guest();
        emit(LoginSuccess());
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });
    on<GoogleLoginRequested>((event, emit) async {
      emit(LoginLoading());
      try {
        await loginRepository.googleLogin();
        emit(LoginSuccess());
      } on GoogleSignInUserCancelled {
        emit(LoginInitial());
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });
  }
}
