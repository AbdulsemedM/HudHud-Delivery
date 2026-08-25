import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repository/forgot_password_repository.dart';

class ForgotPasswordResetState extends Equatable {
  const ForgotPasswordResetState({
    this.loading = false,
    this.error,
  });

  final bool loading;
  final String? error;

  ForgotPasswordResetState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return ForgotPasswordResetState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [loading, error];
}

class ForgotPasswordResetCubit extends Cubit<ForgotPasswordResetState> {
  ForgotPasswordResetCubit(this._repository, {required this.resetToken})
      : super(const ForgotPasswordResetState());

  final ForgotPasswordRepository _repository;
  final String resetToken;

  Future<String?> submit({
    required String password,
    required String passwordConfirmation,
  }) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final message = await _repository.resetPassword(
        resetToken: resetToken,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      emit(state.copyWith(loading: false));
      return message;
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e is String ? e : e.toString(),
      ));
      return null;
    }
  }
}
