import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/forgot_password/bloc/forgot_password_otp_cubit.dart';
import 'package:hudhud_delivery/features/forgot_password/data/repository/forgot_password_repository.dart';
import 'package:hudhud_delivery/features/forgot_password/presentation/screen/forgot_password_new_password_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/login_hero_background.dart';

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

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _otpFieldsKey = GlobalKey<_ForgotPasswordOtpFieldsState>();
  Timer? _timer;
  late DateTime _expiresAt;
  late final AnimationController _cardAnimController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _expiresAt = DateTime.now().add(Duration(minutes: widget.expiresInMinutes));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOut,
    );
    _cardAnimController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cardAnimController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  int get _remainingSeconds {
    final diff = _expiresAt.difference(DateTime.now());
    return diff.inSeconds;
  }

  bool get _expired => _remainingSeconds <= 0;

  Future<void> _verify(ForgotPasswordOtpCubit cubit) async {
    if (_otpFieldsKey.currentState?.validate() != null) return;
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
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final masked = _displayIdentifier(widget.identifier);
          final topHeight = MediaQuery.of(context).size.height * 0.42;

          return Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: topHeight,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryDarkColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const LoginHeroBlobs(),
                        SafeArea(
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.sms_outlined,
                                size: 56,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.forgotPasswordVerifyTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(flex: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              isDark ? theme.colorScheme.surface : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: BlocConsumer<ForgotPasswordOtpCubit,
                              ForgotPasswordOtpState>(
                            listenWhen: (p, c) =>
                                p.error != c.error && c.error != null,
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
                              final cubit =
                                  context.read<ForgotPasswordOtpCubit>();
                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(24, 28, 24, 24),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        l10n.forgotPasswordVerifyTitle,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.forgotPasswordVerifySubtitle(
                                            masked),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.mutedDark
                                              : AppColors.mutedLight,
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
                                              : theme.colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        l10n.forgotPasswordOtpLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _ForgotPasswordOtpFields(
                                        key: _otpFieldsKey,
                                        enabled: !state.verifyLoading &&
                                            !state.resendLoading,
                                        onChanged: (value) {
                                          _otpController.text = value;
                                        },
                                        validator: () {
                                          if (_otpController.text.trim().length !=
                                              6) {
                                            return l10n.validationOtpLength;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: state.resendLoading ||
                                                  state.verifyLoading
                                              ? null
                                              : () => _resend(cubit),
                                          child: state.resendLoading
                                              ? SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: theme
                                                        .colorScheme.primary,
                                                  ),
                                                )
                                              : Text(
                                                  l10n.forgotPasswordResend,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      DecoratedBox(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primaryColor,
                                              AppColors.primaryDarkColor,
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(14),
                                          ),
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: ElevatedButton(
                                            onPressed: (state.verifyLoading ||
                                                    _expired)
                                                ? null
                                                : () => _verify(cubit),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              elevation: 0,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: state.verifyLoading
                                                ? const SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    l10n
                                                        .forgotPasswordVerifyButton,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ForgotPasswordOtpFields extends StatefulWidget {
  const _ForgotPasswordOtpFields({
    super.key,
    required this.enabled,
    required this.onChanged,
    required this.validator,
  });

  final bool enabled;
  final ValueChanged<String> onChanged;
  final String? Function() validator;

  @override
  State<_ForgotPasswordOtpFields> createState() =>
      _ForgotPasswordOtpFieldsState();
}

class _ForgotPasswordOtpFieldsState extends State<_ForgotPasswordOtpFields> {
  static const _length = 6;
  final _controllers =
      List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());
  String? _errorText;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      value = value.substring(value.length - 1);
      _controllers[index].text = value;
      _controllers[index].selection =
          TextSelection.collapsed(offset: value.length);
    }

    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() => _errorText = null);
    _notifyChange();
  }

  String? validate() {
    final error = widget.validator();
    setState(() => _errorText = error);
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = theme.colorScheme.surfaceContainerHighest;
    final borderColor = isDark
        ? AppColors.borderDark
        : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_length, (index) {
            return SizedBox(
              width: 48,
              height: 56,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                enabled: widget.enabled,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: fill,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) => _onChanged(value, index),
                onTap: () {
                  _controllers[index].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _controllers[index].text.length,
                  );
                },
                onEditingComplete: () {
                  if (index < _length - 1) {
                    _focusNodes[index + 1].requestFocus();
                  } else {
                    _focusNodes[index].unfocus();
                  }
                },
              ),
            );
          }),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorText!,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
