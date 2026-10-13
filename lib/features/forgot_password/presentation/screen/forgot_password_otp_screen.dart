import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/forgot_password/bloc/forgot_password_otp_cubit.dart';
import 'package:hudhud_delivery/features/forgot_password/data/repository/forgot_password_repository.dart';
import 'package:hudhud_delivery/features/forgot_password/presentation/screen/forgot_password_new_password_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_dark_scaffold.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_ui.dart';

String _formatMmSs(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final m = s ~/ 60;
  final r = s % 60;
  return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
}

String _displayIdentifier(String raw) {
  final t = raw.trim();
  if (t.contains('@')) {
    final parts = t.split('@');
    if (parts.length == 2 && parts[0].length > 2) {
      return '${parts[0].substring(0, 2)}***@${parts[1]}';
    }
  }
  if (t.length > 4) {
    return '***${t.substring(t.length - 4)}';
  }
  return t;
}

class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({
    super.key,
    required this.resetId,
    required this.identifier,
    required this.expiresInMinutes,
  });

  final String resetId;
  final String identifier;
  final int expiresInMinutes;

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _timer;
  late DateTime _expiresAt;

  @override
  void initState() {
    super.initState();
    _expiresAt = DateTime.now().add(Duration(minutes: widget.expiresInMinutes));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  int get _remainingSeconds {
    final diff = _expiresAt.difference(DateTime.now());
    return diff.inSeconds;
  }

  bool get _expired => _remainingSeconds <= 0;

  Future<void> _verify(ForgotPasswordOtpCubit cubit) async {
    if (!_formKey.currentState!.validate()) return;
    final result = await cubit.verify(_otpController.text.trim());
    if (!mounted || result == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordNewPasswordScreen(
          resetToken: result.resetToken,
        ),
      ),
    );
  }

  Future<void> _resend(ForgotPasswordOtpCubit cubit) async {
    final minutes = await cubit.resend();
    if (!mounted || minutes == null) return;
    setState(() {
      _expiresAt = DateTime.now().add(Duration(minutes: minutes));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordOtpCubit(
        ForgotPasswordRepository.createDefault(),
        resetId: widget.resetId,
      ),
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final masked = _displayIdentifier(widget.identifier);
          return AuthDarkScaffold(
            showBackButton: true,
            child: BlocConsumer<ForgotPasswordOtpCubit, ForgotPasswordOtpState>(
              listenWhen: (p, c) => p.error != c.error && c.error != null,
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final cubit = context.read<ForgotPasswordOtpCubit>();
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      AuthHeading(
                        icon: Icons.sms_rounded,
                        title: l10n.forgotPasswordVerifyTitle,
                        subtitle: l10n.forgotPasswordVerifySubtitle(masked),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AuthPill(
                          error: _expired,
                          icon: _expired
                              ? Icons.timer_off_rounded
                              : Icons.schedule_rounded,
                          label: _expired
                              ? l10n.forgotPasswordCodeExpired
                              : l10n.forgotPasswordTimeRemaining(
                                  _formatMmSs(_remainingSeconds),
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AuthFieldLabel(l10n.forgotPasswordOtpLabel),
                      AuthCodeField(
                        controller: _otpController,
                        length: 6,
                        enabled: !state.verifyLoading && !state.resendLoading,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.length != 6) {
                            return l10n.validationOtpLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AuthScreenColors.orange,
                            minimumSize: const Size(48, 48),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          onPressed: state.resendLoading || state.verifyLoading
                              ? null
                              : () => _resend(cubit),
                          label: state.resendLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AuthScreenColors.orange,
                                  ),
                                )
                              : Text(l10n.forgotPasswordResend),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AuthGradientButton(
                        label: l10n.forgotPasswordVerifyButton,
                        loading: state.verifyLoading,
                        onPressed: (state.verifyLoading || _expired)
                            ? null
                            : () => _verify(cubit),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
