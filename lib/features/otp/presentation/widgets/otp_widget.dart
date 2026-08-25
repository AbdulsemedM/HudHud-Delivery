import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';

class OtpInputFields extends StatefulWidget {
  final Function(String)? onCompleted;

  const OtpInputFields({Key? key, this.onCompleted}) : super(key: key);

  @override
  State<OtpInputFields> createState() => OtpInputFieldsState();
}

class OtpInputFieldsState extends State<OtpInputFields> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<String> _otpValues = ['', '', '', ''];

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onDigitEntered(String value, int index) {
    if (value.length > 1) {
      value = value.substring(0, 1);
    }

    setState(() {
      _otpValues[index] = value;
    });

    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_otpValues.every((v) => v.isNotEmpty)) {
      final otp = _otpValues.join('');
      widget.onCompleted?.call(otp);
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

  void _insertDigit(String digit) {
    for (int i = 0; i < 4; i++) {
      if (_otpValues[i].isEmpty) {
        setState(() {
          _otpValues[i] = digit;
          _controllers[i].text = digit;
        });
        if (i < 3) {
          _focusNodes[i + 1].requestFocus();
        } else {
          _focusNodes[i].unfocus();
        }
        break;
      }
    }

    if (_otpValues.every((v) => v.isNotEmpty)) {
      final otp = _otpValues.join('');
      widget.onCompleted?.call(otp);
    }
  }

  InputDecoration _otpDecoration(BuildContext context, bool isFocused) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InputDecoration(
      counterText: '',
      filled: true,
      fillColor: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isFocused ? AppColors.primaryColor : borderColor,
          width: isFocused ? 2 : 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return SizedBox(
          width: 64,
          height: 64,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.none,
            maxLength: 1,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            decoration: _otpDecoration(
              context,
              _focusNodes[index].hasFocus,
            ),
            onChanged: (value) => _onDigitEntered(value, index),
            onTap: () {
              if (_otpValues[index].isNotEmpty) {
                setState(() {
                  _otpValues[index] = '';
                  _controllers[index].clear();
                });
              }
            },
          ),
        );
      }),
    );
  }

  void handleKeyboardInput(String input) {
    if (input == 'backspace') {
      int lastFilledIndex = -1;
      for (int i = 3; i >= 0; i--) {
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
      _insertDigit(input);
    }
  }

  List<String> get otpValues => _otpValues;
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
        content: Text(l10n.codeSentPhoneDefault),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
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
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_canResend) ...[
          Text(
            '${l10n.actionResend} ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            _formatTime(_remainingSeconds),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ] else
          GestureDetector(
            onTap: _resendCode,
            child: Text(
              l10n.actionResend,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primaryColor,
              ),
            ),
          ),
      ],
    );
  }
}

class OtpNumericKeyboard extends StatelessWidget {
  final Function(String)? onKeyPressed;
  final OtpInputFieldsState? otpInputFieldsState;

  const OtpNumericKeyboard({
    Key? key,
    this.onKeyPressed,
    this.otpInputFieldsState,
  }) : super(key: key);

  void _handleKeyPress(String key, BuildContext context) {
    final l10n = context.l10n;
    if (key == 'backspace') {
      otpInputFieldsState?.handleKeyboardInput('backspace');
      onKeyPressed?.call('backspace');
    } else if (key == 'submit') {
      // TODO: Implement submit OTP logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.actionSending),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    } else {
      otpInputFieldsState?.handleKeyboardInput(key);
      onKeyPressed?.call(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyBg = isDark ? AppColors.darkInputFill : AppColors.lightSurface;
    final keyBorder =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final panelBg = isDark ? AppColors.darkSurface : AppColors.lightBackground;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(
          top: BorderSide(color: keyBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberKey(
                  '1',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('1', context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberKey(
                  '2',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('2', context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberKey(
                  '3',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('3', context),
                ),
              ),
              const SizedBox(width: 8),
              _SpecialKey(
                Icons.remove,
                color: isDark ? AppColors.darkBorder : AppColors.lightInputFill,
                onPressed: () => _handleKeyPress('-', context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberKey(
                  '4',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('4', context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberKey(
                  '5',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('5', context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberKey(
                  '6',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('6', context),
                ),
              ),
              const SizedBox(width: 8),
              _SpecialKey(
                Icons.code,
                color: isDark ? AppColors.darkBorder : AppColors.lightInputFill,
                onPressed: () => _handleKeyPress(']', context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberKey(
                  '7',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('7', context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberKey(
                  '8',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('8', context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberKey(
                  '9',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('9', context),
                ),
              ),
              const SizedBox(width: 8),
              _SpecialKey(
                Icons.backspace_outlined,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                onPressed: () => _handleKeyPress('backspace', context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberKey(
                  ',',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress(',', context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberKey(
                  '0',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('0', context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberKey(
                  '.',
                  keyBg: keyBg,
                  keyBorder: keyBorder,
                  onPressed: () => _handleKeyPress('.', context),
                ),
              ),
              const SizedBox(width: 8),
              _SubmitKey(
                onPressed: () => _handleKeyPress('submit', context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberKey extends StatelessWidget {
  final String number;
  final Color keyBg;
  final Color keyBorder;
  final VoidCallback onPressed;

  const _NumberKey(
    this.number, {
    required this.keyBg,
    required this.keyBorder,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: keyBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: keyBorder, width: 1),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialKey extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _SpecialKey(
    this.icon, {
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SubmitKey extends StatelessWidget {
  final VoidCallback onPressed;

  const _SubmitKey({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Transform.rotate(
            angle: 3.14159,
            child: const Icon(
              Icons.arrow_forward,
              color: AppColors.lightOnPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
