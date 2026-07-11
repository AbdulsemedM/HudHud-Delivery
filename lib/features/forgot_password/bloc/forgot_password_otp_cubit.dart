import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repository/forgot_password_repository.dart';

class ForgotPasswordOtpState extends Equatable {
  const ForgotPasswordOtpState({
    this.verifyLoading = false,
    this.resendLoading = false,
    this.error,
  });

  final bool verifyLoading;
  final bool resendLoading;
  final String? error;

  ForgotPasswordOtpState copyWith({
    bool? verifyLoading,
    bool? resendLoading,
    String? error,
    bool clearError = false,
  }) {
    return ForgotPasswordOtpState(
      verifyLoading: verifyLoading ?? this.verifyLoading,
      resendLoading: resendLoading ?? this.resendLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [verifyLoading, resendLoading, error];
}

class ForgotPasswordOtpCubit extends Cubit<ForgotPasswordOtpState> {
  ForgotPasswordOtpCubit(this._repository, {required this.resetId})
      : super(const ForgotPasswordOtpState());

  final ForgotPasswordRepository _repository;
  final String resetId;

  Future<VerifyOtpResult?> verify(String otp) async {
    emit(state.copyWith(verifyLoading: true, clearError: true));
    try {
      final result = await _repository.verifyOtp(resetId: resetId, otp: otp);
      emit(state.copyWith(verifyLoading: false));
      return result;
    } catch (e) {
      emit(state.copyWith(
        verifyLoading: false,
        error: e is String ? e : e.toString(),
      ));
      return null;
    }
  }

  /// Returns new expiry minutes for UI timer, or null if not provided.
  Future<int?> resend() async {
    emit(state.copyWith(resendLoading: true, clearError: true));
    try {
      final minutes = await _repository.resendOtp(resetId);
      emit(state.copyWith(resendLoading: false));
      return minutes;
    } catch (e) {
      emit(state.copyWith(
        resendLoading: false,
        error: e is String ? e : e.toString(),
      ));
      return null;
    }
  }
}
