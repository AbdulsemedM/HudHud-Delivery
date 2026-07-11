import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repository/forgot_password_repository.dart';

class ForgotPasswordRequestState extends Equatable {
  const ForgotPasswordRequestState({
    this.loading = false,
    this.error,
  });

  final bool loading;
  final String? error;

  ForgotPasswordRequestState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return ForgotPasswordRequestState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [loading, error];
}

class ForgotPasswordRequestCubit extends Cubit<ForgotPasswordRequestState> {
  ForgotPasswordRequestCubit(this._repository)
      : super(const ForgotPasswordRequestState());

  final ForgotPasswordRepository _repository;

  Future<ResetOtpResult?> submit(String identifier) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final result = await _repository.requestResetOtp(identifier);
      emit(state.copyWith(loading: false));
      return result;
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e is String ? e : e.toString(),
      ));
      return null;
    }
  }
}
