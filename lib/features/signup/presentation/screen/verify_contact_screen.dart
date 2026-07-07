import 'package:flutter/material.dart';

import '../../../../app/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/user_model.dart';
import '../../../dashboard/presentation/screen/dashboard_screen.dart';

class VerifyContactScreen extends StatefulWidget {
  final bool resumeAfterAuth;

  const VerifyContactScreen({super.key, this.resumeAfterAuth = false});

  @override
  State<VerifyContactScreen> createState() => _VerifyContactScreenState();
}

class _VerifyContactScreenState extends State<VerifyContactScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailCodeController = TextEditingController();
  final TextEditingController _phoneCodeController = TextEditingController();

  String? _email;
  String? _phone;
  bool _emailVerified = false;
  bool _phoneVerified = false;

  bool _isLoadingUser = true;
  bool _isSendingEmailCode = false;
  bool _isSendingPhoneCode = false;
  bool _isVerifyingEmail = false;
  bool _isVerifyingPhone = false;

  @override
  void initState() {
    super.initState();
    _initializeVerificationState();
  }

  @override
  void dispose() {
    _emailCodeController.dispose();
    _phoneCodeController.dispose();
    super.dispose();
  }

  Future<void> _initializeVerificationState() async {
    UserModel? user = _authService.currentUser;
    user ??= await _authService.getStoredUser();
    user ??= await _authService.getUserProfile(forceRefresh: true);

    if (!mounted) return;

    setState(() {
      _email = user?.email;
      _phone = user?.phone;
      _emailVerified = user?.isEmailVerified ?? false;
      _phoneVerified = user?.isPhoneVerified ?? false;
      _isLoadingUser = false;
    });

    if (!_emailVerified && (_email?.isNotEmpty ?? false)) {
      _sendEmailCode(silent: true);
    }
    if (!_phoneVerified && (_phone?.isNotEmpty ?? false)) {
      _sendPhoneCode(silent: true);
    }
  }

  Future<void> _sendEmailCode({bool silent = false}) async {
    if (_isSendingEmailCode || (_email?.isEmpty ?? true)) return;
    setState(() => _isSendingEmailCode = true);

    final response = await _authService.sendEmailVerification();
    if (!mounted) return;

    setState(() => _isSendingEmailCode = false);
    if (!silent) {
      _showSnack(response['message'] ?? 'Unable to send email code', response['success'] == true);
    }
  }

  Future<void> _sendPhoneCode({bool silent = false}) async {
    if (_isSendingPhoneCode || (_phone?.isEmpty ?? true)) return;
    setState(() => _isSendingPhoneCode = true);

    final response = await _authService.sendPhoneVerificationCode(_phone!);
    if (!mounted) return;

    setState(() => _isSendingPhoneCode = false);
    if (!silent) {
      _showSnack(response['message'] ?? 'Unable to send phone code', response['success'] == true);
    }
  }

  Future<void> _verifyEmail() async {
    final code = _emailCodeController.text.trim();
    if (code.isEmpty || (_email?.isEmpty ?? true)) {
      _showSnack('Enter the email verification code first', false);
      return;
    }

    setState(() => _isVerifyingEmail = true);
    final response = await _authService.verifyEmail(email: _email!, code: code);
    if (!mounted) return;

    setState(() {
      _isVerifyingEmail = false;
      _emailVerified = response['success'] == true ? true : _emailVerified;
      if (response['success'] == true) _emailCodeController.clear();
    });

    _showSnack(response['message'] ?? 'Email verification failed', response['success'] == true);
  }

  Future<void> _verifyPhone() async {
    final code = _phoneCodeController.text.trim();
    if (code.isEmpty || (_phone?.isEmpty ?? true)) {
      _showSnack('Enter the phone verification code first', false);
      return;
    }

    setState(() => _isVerifyingPhone = true);
    final response = await _authService.verifyPhone(phone: _phone!, code: code);
    if (!mounted) return;

    setState(() {
      _isVerifyingPhone = false;
      _phoneVerified = response['success'] == true ? true : _phoneVerified;
      if (response['success'] == true) _phoneCodeController.clear();
    });

    _showSnack(response['message'] ?? 'Phone verification failed', response['success'] == true);
  }

  void _showSnack(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.successColor : AppColors.errorColor,
      ),
    );
  }

  void _goToDashboard() {
    if (widget.resumeAfterAuth) {
      Navigator.pop(context, true);
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allVerified = _emailVerified && _phoneVerified;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5EE), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: _isLoadingUser
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.verified_user_outlined, color: AppColors.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Verify Email & Phone',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _goToDashboard,
                            child: const Text('Skip'),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'A verification code was sent by email and SMS. Verify now for a more secure account.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          children: [
                            _VerificationCard(
                              title: 'Email Verification',
                              subtitle: _email ?? 'No email available',
                              icon: Icons.email_outlined,
                              isVerified: _emailVerified,
                              controller: _emailCodeController,
                              hintText: 'Enter email code',
                              verifyLabel: 'Verify Email',
                              onVerify: _verifyEmail,
                              onResend: _sendEmailCode,
                              isVerifying: _isVerifyingEmail,
                              isResending: _isSendingEmailCode,
                            ),
                            const SizedBox(height: 14),
                            _VerificationCard(
                              title: 'Phone Verification',
                              subtitle: _phone ?? 'No phone number available',
                              icon: Icons.sms_outlined,
                              isVerified: _phoneVerified,
                              controller: _phoneCodeController,
                              hintText: 'Enter SMS code',
                              verifyLabel: 'Verify Phone',
                              onVerify: _verifyPhone,
                              onResend: _sendPhoneCode,
                              isVerifying: _isVerifyingPhone,
                              isResending: _isSendingPhoneCode,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _goToDashboard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: allVerified ? AppColors.successColor : AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  allVerified ? 'Continue to Dashboard' : 'Skip for now',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isVerified;
  final TextEditingController controller;
  final String hintText;
  final String verifyLabel;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final bool isVerifying;
  final bool isResending;

  const _VerificationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isVerified,
    required this.controller,
    required this.hintText,
    required this.verifyLabel,
    required this.onVerify,
    required this.onResend,
    required this.isVerifying,
    required this.isResending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isVerified ? AppColors.successColor.withOpacity(0.4) : const Color(0xFFE7E9EE),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isVerified
                      ? AppColors.successColor.withOpacity(0.12)
                      : AppColors.secondaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isVerified ? Icons.check_circle_outline : icon,
                  color: isVerified ? AppColors.successColor : AppColors.secondaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(
                      color: AppColors.successColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            enabled: !isVerified,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isVerified || isResending ? null : onResend,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.primaryColor),
                  ),
                  child: isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend Code'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isVerified || isVerifying ? null : onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(verifyLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
