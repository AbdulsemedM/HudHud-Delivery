import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class OtpInputFields extends StatefulWidget {
  final ValueChanged<String>? onCompleted;

  const OtpInputFields({super.key, this.onCompleted});

  @override
  State<OtpInputFields> createState() => OtpInputFieldsState();
}

class OtpInputFieldsState extends State<OtpInputFields> {
  static const _length = 6;
  final _controllers =
      List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());
  final _otpValues = List.filled(_length, '');

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onDigitEntered(String value, int index) {
    if (value.length > 1) {
      value = value.substring(value.length - 1);
      _controllers[index].text = value;
      _controllers[index].selection =
          TextSelection.collapsed(offset: value.length);
    }

    setState(() {
      _otpValues[index] = value;
    });

    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_otpValues.every((v) => v.isNotEmpty)) {
      widget.onCompleted?.call(_otpValues.join());
    }
  }

  void _onBackspace(int index) {
    if (_otpValues[index].isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      setState(() {
        _otpValues[index - 1] = '';
        _controllers[index - 1].clear();
      });
    } else {
      setState(() {
        _otpValues[index] = '';
        _controllers[index].clear();
      });
    }
  }

  void handleKeyboardInput(String input) {
    if (input == 'backspace') {
      int lastFilledIndex = -1;
      for (int i = _length - 1; i >= 0; i--) {
        if (_otpValues[i].isNotEmpty) {
          lastFilledIndex = i;
          break;
        }
      }
      if (lastFilledIndex >= 0) {
        _onBackspace(lastFilledIndex);
        if (lastFilledIndex > 0) {
          _focusNodes[lastFilledIndex - 1].requestFocus();
        } else {
          _focusNodes[0].requestFocus();
        }
      }
    } else if (RegExp(r'^[0-9]$').hasMatch(input)) {
      for (int i = 0; i < _length; i++) {
        if (_otpValues[i].isEmpty) {
          setState(() {
            _otpValues[i] = input;
            _controllers[i].text = input;
          });
          if (i < _length - 1) {
            _focusNodes[i + 1].requestFocus();
          } else {
            _focusNodes[i].unfocus();
          }
          break;
        }
      }
      if (_otpValues.every((v) => v.isNotEmpty)) {
        widget.onCompleted?.call(_otpValues.join());
      }
    }
  }

  List<String> get otpValues => List.unmodifiable(_otpValues);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = theme.colorScheme.surfaceContainerHighest;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_length, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
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
            ),
            onChanged: (value) => _onDigitEntered(value, index),
            onTap: () {
              _controllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controllers[index].text.length,
              );
            },
          ),
        );
      }),
    );
  }
}

class OtpResendTimer extends StatefulWidget {
  const OtpResendTimer({super.key});

  @override
  State<OtpResendTimer> createState() => _OtpResendTimerState();
}

class _OtpResendTimerState extends State<OtpResendTimer> {
  Timer? _timer;
  int _remainingSeconds = 180;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  void _resendCode() {
    final l10n = context.l10n;
    setState(() {
      _remainingSeconds = 180;
      _canResend = false;
    });
    _startTimer();
    // TODO: Implement resend OTP logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.actionResend),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_canResend)
          Text(
            l10n.forgotPasswordTimeRemaining(_formatTime(_remainingSeconds)),
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          GestureDetector(
            onTap: _resendCode,
            child: Text(
              l10n.actionResend,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }
}
