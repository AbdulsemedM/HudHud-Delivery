import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../models/user_model.dart';
import '../../../dashboard/presentation/screen/dashboard_screen.dart';

class VerifyContactScreen extends StatefulWidget {
  const VerifyContactScreen({super.key});

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
  String? _loadError;
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
    setState(() {
      _isLoadingUser = true;
      _loadError = null;
    });

    try {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingUser = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _sendEmailCode({bool silent = false}) async {
    if (_isSendingEmailCode || (_email?.isEmpty ?? true)) return;
    final l10n = context.l10n;
    setState(() => _isSendingEmailCode = true);

    final response = await _authService.sendEmailVerification();
    if (!mounted) return;

    setState(() => _isSendingEmailCode = false);
    if (!silent) {
      _showSnack(
        response['message'] ?? l10n.codeSentEmailDefault,
        response['success'] == true,
      );
    }
  }

  Future<void> _sendPhoneCode({bool silent = false}) async {
    if (_isSendingPhoneCode || (_phone?.isEmpty ?? true)) return;
    final l10n = context.l10n;
    setState(() => _isSendingPhoneCode = true);

    final response = await _authService.sendPhoneVerificationCode(_phone!);
    if (!mounted) return;

    setState(() => _isSendingPhoneCode = false);
    if (!silent) {
      _showSnack(
        response['message'] ?? l10n.codeSentPhoneDefault,
        response['success'] == true,
      );
    }
  }

  Future<void> _verifyEmail() async {
    final l10n = context.l10n;
    final code = _emailCodeController.text.trim();
    if (code.isEmpty || (_email?.isEmpty ?? true)) {
      _showSnack(l10n.enterVerificationCodeError, false);
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

    _showSnack(
      response['message'] ?? l10n.enterVerificationCodeError,
      response['success'] == true,
    );
  }

  Future<void> _verifyPhone() async {
    final l10n = context.l10n;
    final code = _phoneCodeController.text.trim();
    if (code.isEmpty || (_phone?.isEmpty ?? true)) {
      _showSnack(l10n.enterVerificationCodeError, false);
      return;
    }

    setState(() => _isVerifyingPhone = true);
    final response =
        await _authService.verifyPhone(phone: _phone!, code: code);
    if (!mounted) return;

    setState(() {
      _isVerifyingPhone = false;
      _phoneVerified = response['success'] == true ? true : _phoneVerified;
      if (response['success'] == true) _phoneCodeController.clear();
    });

    _showSnack(
      response['message'] ?? l10n.enterVerificationCodeError,
      response['success'] == true,
    );
  }

  void _showSnack(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isSuccess ? AppColors.successColor : AppColors.errorColor,
      ),
    );
  }

  void _goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
  }

  Color _cardBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
  }

  InputDecoration _codeFieldDecoration(BuildContext context, String hint) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F4F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allVerified = _emailVerified && _phoneVerified;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.22,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.0),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.verificationStatus,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _goToDashboard,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.actionSkip),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: _isLoadingUser
                    ? const _VerifyContactShimmer()
                    : _loadError != null
                        ? _VerifyContactErrorView(
                            message: l10n.profileLoadFailed(_loadError!),
                            onRetry: _initializeVerificationState,
                          )
                        : SingleChildScrollView(
                            padding:
                                const EdgeInsets.fromLTRB(24, 24, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.codeSentEmailDefault,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.codeSentPhoneDefault,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: AppColors.spaceLG),
                                _VerificationCard(
                                  title: l10n.emailVerificationTitle,
                                  subtitle:
                                      _email ?? l10n.noEmailAvailable,
                                  icon: Icons.email_outlined,
                                  isVerified: _emailVerified,
                                  controller: _emailCodeController,
                                  hintText: l10n.enterEmailCode,
                                  verifyLabel: l10n.verifyEmail,
                                  resendLabel: l10n.actionResend,
                                  onVerify: _verifyEmail,
                                  onResend: _sendEmailCode,
                                  isVerifying: _isVerifyingEmail,
                                  isResending: _isSendingEmailCode,
                                  borderColor: _cardBorderColor(context),
                                  fieldDecoration: _codeFieldDecoration(
                                    context,
                                    l10n.enterEmailCode,
                                  ),
                                ),
                                const SizedBox(height: AppColors.spaceMD),
                                _VerificationCard(
                                  title: l10n.phoneVerificationTitle,
                                  subtitle:
                                      _phone ?? l10n.noPhoneAvailable,
                                  icon: Icons.sms_outlined,
                                  isVerified: _phoneVerified,
                                  controller: _phoneCodeController,
                                  hintText: l10n.enterSmsCode,
                                  verifyLabel: l10n.verifyPhone,
                                  resendLabel: l10n.actionResend,
                                  onVerify: _verifyPhone,
                                  onResend: _sendPhoneCode,
                                  isVerifying: _isVerifyingPhone,
                                  isResending: _isSendingPhoneCode,
                                  borderColor: _cardBorderColor(context),
                                  fieldDecoration: _codeFieldDecoration(
                                    context,
                                    l10n.enterSmsCode,
                                  ),
                                ),
                                const SizedBox(height: AppColors.spaceLG),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: allVerified
                                            ? [
                                                AppColors.successColor,
                                                AppColors.successLightColor,
                                              ]
                                            : AppColors.primaryGradient,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _goToDashboard,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        allVerified
                                            ? l10n.actionContinue
                                            : l10n.actionSkip,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyContactShimmer extends StatelessWidget {
  const _VerifyContactShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final highlight = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF4F4F4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          children: [
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: AppColors.spaceMD),
            ...List.generate(2, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == 0 ? 16 : 0),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppColors.spaceLG),
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifyContactErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _VerifyContactErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppColors.spaceMD),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppColors.spaceMD),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.actionRetry),
            ),
          ],
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
  final String resendLabel;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final bool isVerifying;
  final bool isResending;
  final Color borderColor;
  final InputDecoration fieldDecoration;

  const _VerificationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isVerified,
    required this.controller,
    required this.hintText,
    required this.verifyLabel,
    required this.resendLabel,
    required this.onVerify,
    required this.onResend,
    required this.isVerifying,
    required this.isResending,
    required this.borderColor,
    required this.fieldDecoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified
              ? AppColors.successColor.withOpacity(0.4)
              : borderColor,
        ),
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
                      : AppColors.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isVerified ? Icons.check_circle_outline : icon,
                  color: isVerified
                      ? AppColors.successColor
                      : AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                const StatusChip(status: 'completed'),
            ],
          ),
          const SizedBox(height: AppColors.spaceMD),
          TextField(
            controller: controller,
            enabled: !isVerified,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
            decoration: fieldDecoration.copyWith(hintText: hintText),
          ),
          const SizedBox(height: AppColors.spaceMD),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: isVerified || isResending ? null : onResend,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: AppColors.primaryColor),
                    ),
                    child: isResending
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryColor,
                            ),
                          )
                        : Text(resendLabel),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed:
                          isVerified || isVerifying ? null : onVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
