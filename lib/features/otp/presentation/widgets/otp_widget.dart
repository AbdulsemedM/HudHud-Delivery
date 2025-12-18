import 'package:flutter/material.dart';
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
  List<String> _otpValues = ['', '', '', ''];

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
      // Handle paste
      value = value.substring(0, 1);
    }

    setState(() {
      _otpValues[index] = value;
    });

    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    // Check if all fields are filled
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

    // Check if all fields are filled
    if (_otpValues.every((v) => v.isNotEmpty)) {
      final otp = _otpValues.join('');
      widget.onCompleted?.call(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Container(
          width: 60,
          height: 60,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.none,
            maxLength: 1,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
              ),
            ),
            onChanged: (value) => _onDigitEntered(value, index),
            onTap: () {
              // Clear field when tapped
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

  // Method to be called from keyboard
  void handleKeyboardInput(String input) {
    if (input == 'backspace') {
      // Find the last filled field
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

  // Get current OTP values for keyboard access
  List<String> get otpValues => _otpValues;
}

class OtpResendTimer extends StatefulWidget {
  @override
  State<OtpResendTimer> createState() => _OtpResendTimerState();
}

class _OtpResendTimerState extends State<OtpResendTimer> {
  Timer? _timer;
  int _remainingSeconds = 180; // 3 minutes = 180 seconds
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
    setState(() {
      _remainingSeconds = 180;
      _canResend = false;
    });
    _startTimer();
    // TODO: Implement resend OTP logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification code resent'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_canResend) ...[
          Text(
            'Resend Code in ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            _formatTime(_remainingSeconds),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ] else
          GestureDetector(
            onTap: _resendCode,
            child: Text(
              'Resend Code',
              style: TextStyle(
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

class OtpNumericKeyboard extends StatelessWidget {
  final Function(String)? onKeyPressed;
  final OtpInputFieldsState? otpInputFieldsState;

  const OtpNumericKeyboard({
    Key? key,
    this.onKeyPressed,
    this.otpInputFieldsState,
  }) : super(key: key);

  void _handleKeyPress(String key, BuildContext context) {
    if (key == 'backspace') {
      otpInputFieldsState?.handleKeyboardInput('backspace');
      onKeyPressed?.call('backspace');
    } else if (key == 'submit') {
      // TODO: Implement submit OTP logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submitting OTP...'),
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Row 1: 1, 2, 3, Special Keys
          Row(
            children: [
              Expanded(
                  child: _NumberKey('1', () => _handleKeyPress('1', context))),
              SizedBox(width: 8),
              Expanded(
                  child: _NumberKey('2', () => _handleKeyPress('2', context))),
              SizedBox(width: 8),
              Expanded(
                  child: _NumberKey('3', () => _handleKeyPress('3', context))),
              SizedBox(width: 8),
              _SpecialKey(Icons.remove, Colors.grey[300]!,
                  () => _handleKeyPress('-', context)),
            ],
          ),
          SizedBox(height: 8),
          // Row 2: 4, 5, 6, Special Keys
          Row(
            children: [
              Expanded(
                  child: _NumberKey('4', () => _handleKeyPress('4', context))),
              SizedBox(width: 8),
              Expanded(
                  child: _NumberKey('5', () => _handleKeyPress('5', context))),
              SizedBox(width: 8),
              Expanded(
                  child: _NumberKey('6', () => _handleKeyPress('6', context))),
              SizedBox(width: 8),
              _SpecialKey(Icons.code, Colors.grey[300]!,
                  () => _handleKeyPress(']', context)),
            ],
          ),
          SizedBox(height: 8),
          // Row 3: 7, 8, 9, Backspace
          Row(
            children: [
              Expanded(
                  child: _NumberKey('7', () => _handleKeyPress('7', context))),
              SizedBox(width: 8),
              Expanded(
                  child: _NumberKey('8', () => _handleKeyPress('8', context))),
              SizedBox(width: 8),
              Expanded(
                  child: _NumberKey('9', () => _handleKeyPress('9', context))),
              SizedBox(width: 8),
              _SpecialKey(Icons.backspace_outlined, Colors.grey[400]!,
                  () => _handleKeyPress('backspace', context)),
            ],
          ),
          SizedBox(height: 8),
          // Row 4: Comma, 0, Period, Submit
          Row(
            children: [
              Expanded(
                  child: _NumberKey(',', () => _handleKeyPress(',', context))),
              SizedBox(width: 8),
              Expanded(
                  child: _NumberKey('0', () => _handleKeyPress('0', context))),
              SizedBox(width: 8),
              Expanded(
                  child: _NumberKey('.', () => _handleKeyPress('.', context))),
              SizedBox(width: 8),
              _SubmitKey(() => _handleKeyPress('submit', context)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberKey extends StatelessWidget {
  final String number;
  final VoidCallback onPressed;

  const _NumberKey(this.number, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
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

  const _SpecialKey(this.icon, this.color, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Colors.grey[700],
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SubmitKey extends StatelessWidget {
  final VoidCallback onPressed;

  const _SubmitKey(this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: 3.14159, // 180 degrees rotation to make arrow point left
            child: Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
