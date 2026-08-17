import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/snackbar_util.dart';

/// Shows the phone OTP verification dialog. Returns `true` when verified.
Future<bool?> showVerifyPhoneDialog(
  BuildContext context, {
  required String phone,
  AuthService? authService,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => VerifyPhoneDialog(
      phone: phone,
      authService: authService ?? AuthService(),
    ),
  );
}

class VerifyPhoneDialog extends StatefulWidget {
  final String phone;
  final AuthService authService;

  const VerifyPhoneDialog({
    super.key,
    required this.phone,
    required this.authService,
  });

  @override
  State<VerifyPhoneDialog> createState() => _VerifyPhoneDialogState();
}

class _VerifyPhoneDialogState extends State<VerifyPhoneDialog> {
  final _codeController = TextEditingController();
  bool _isSending = false;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    final result =
        await widget.authService.sendPhoneVerificationCode(widget.phone);
    if (!mounted) return;
    setState(() => _isSending = false);
    if (result['success'] == true) {
      SnackbarUtil.showSuccess(
        context,
        result['message'] ?? context.l10n.codeSentPhoneDefault,
      );
    } else {
      setState(() => _errorMessage = result['message'] as String?);
    }
  }

  Future<void> _verify() async {
    final l10n = context.l10n;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = l10n.enterVerificationCodeError);
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    final result = await widget.authService.verifyPhone(
      phone: widget.phone,
      code: code,
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);
    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = result['message'] as String?);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.verifyPhoneDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.verifyPhoneBody(widget.phone),
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: l10n.verificationCodeLabel,
                hintText: l10n.verificationCodeHintSms,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSending ? null : _sendCode,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sms_outlined, size: 18),
              label: Text(
                _isSending ? l10n.actionSending : l10n.actionResend,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _isVerifying ? null : _verify,
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.actionVerify),
        ),
      ],
    );
  }
}
