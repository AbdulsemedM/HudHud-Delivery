import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/forgot_password/bloc/forgot_password_otp_cubit.dart';
import 'package:hudhud_delivery/features/forgot_password/data/repository/forgot_password_repository.dart';
import 'package:hudhud_delivery/features/forgot_password/presentation/screen/forgot_password_new_password_screen.dart';

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
    final result =
        await cubit.verify(_otpController.text.trim());
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
          final theme = Theme.of(context);
          final masked = _displayIdentifier(widget.identifier);
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: BlocConsumer<ForgotPasswordOtpCubit, ForgotPasswordOtpState>(
                listenWhen: (p, c) => p.error != c.error && c.error != null,
                listener: (context, state) {
                  if (state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error!),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final cubit = context.read<ForgotPasswordOtpCubit>();
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.forgotPasswordVerifyTitle,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.forgotPasswordVerifySubtitle(masked),
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _expired
                                ? l10n.forgotPasswordCodeExpired
                                : l10n.forgotPasswordTimeRemaining(
                                    _formatMmSs(_remainingSeconds),
                                  ),
                            style: TextStyle(
                              fontSize: 13,
                              color: _expired
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.forgotPasswordOtpLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            enabled: !state.verifyLoading && !state.resendLoading,
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
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
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: state.resendLoading || state.verifyLoading
                                  ? null
                                  : () => _resend(cubit),
                              child: state.resendLoading
                                  ? SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.primary,
                                      ),
                                    )
                                  : Text(
                                      l10n.forgotPasswordResend,
                                      style: const TextStyle(
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: (state.verifyLoading || _expired)
                                  ? null
                                  : () => _verify(cubit),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: state.verifyLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      l10n.forgotPasswordVerifyButton,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
