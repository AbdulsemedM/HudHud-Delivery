import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../data/repository/login_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository loginRepository;
  LoginBloc(this.loginRepository) : super(LoginInitial()) {
    on<LoginFormSubmitted>((event, emit) async {
      emit(LoginLoading());
      // Bypass API call for now - directly emit success
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay for UX
      emit(LoginSuccess());
      
      // Original API call code (commented out for now)
      // try {
      //   await loginRepository.login(event.emailOrPhone, event.password, event.fieldType);
      //   emit(LoginSuccess());
      // } catch (e) {
      //   emit(LoginFailure(e.toString()));
      // }
    });
  }
}
