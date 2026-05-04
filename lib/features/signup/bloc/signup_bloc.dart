import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../data/repository/signup_repository.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final SignupRepository _signupRepository;
  SignupBloc(this._signupRepository) : super(SignupInitial()) {
    on<SignupFormSubmitted>((event, emit) async {
      emit(SignupLoading());
      try {
        await _signupRepository.signup(
          event.name,
          event.email,
          event.phone,
          event.password,
          event.confirmPassword,
          referralCode: event.referralCode,
        );
        emit(SignupSuccess());
      } catch (e) {
        emit(SignupFailure(e.toString()));
      }
    });
  }
}
