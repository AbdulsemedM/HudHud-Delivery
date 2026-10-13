import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../models/user_model.dart';
import '../../../dashboard/presentation/screen/dashboard_screen.dart';
import '../../../home/presentation/theme/home_colors.dart';
import '../../../login/presentation/theme/auth_screen_colors.dart';
import '../../../login/presentation/widgets/auth_dark_scaffold.dart';
import '../../../login/presentation/widgets/auth_field_decoration.dart';
import '../../../login/presentation/widgets/auth_gradient_button.dart';
import '../../../login/presentation/widgets/auth_ui.dart';

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
    final response = await _authService.verifyPhone(phone: _phone!, code: code);
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
    final l10n = context.l10n;
    final allVerified = _emailVerified && _phoneVerified;

    return AuthScaffold(
      showBackButton: false,
      child: _isLoadingUser
          ? const _VerifyContactShimmer()
          : _loadError != null
              ? _VerifyContactErrorView(
                  message: l10n.profileLoadFailed(_loadError!),
                  onRetry: _initializeVerificationState,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthHeroIcon(
                          icon: allVerified
                              ? Icons.verified_rounded
                              : Icons.verified_user_rounded,
                          indigo: !allVerified,
                        ),
                        const Spacer(),
                        if (!allVerified)
                          TextButton(
                            onPressed: _goToDashboard,
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  AuthScreenColors.textSecondaryOf(context),
                              minimumSize: const Size(48, 48),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text(l10n.actionSkip),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    AuthHeading(
                      title: l10n.verificationStatus,
                      subtitle:
                          '${l10n.codeSentEmailDefault}\n${l10n.codeSentPhoneDefault}',
                    ),
                    const SizedBox(height: 24),
                    _VerificationCard(
                      title: l10n.emailVerificationTitle,
                      subtitle: _email ?? l10n.noEmailAvailable,
                      icon: Icons.mark_email_unread_rounded,
                      isVerified: _emailVerified,
                      controller: _emailCodeController,
                      hintText: l10n.enterEmailCode,
                      verifyLabel: l10n.verifyEmail,
                      resendLabel: l10n.actionResend,
                      onVerify: _verifyEmail,
                      onResend: _sendEmailCode,
                      isVerifying: _isVerifyingEmail,
                      isResending: _isSendingEmailCode,
                    ),
                    const SizedBox(height: 16),
                    _VerificationCard(
                      title: l10n.phoneVerificationTitle,
                      subtitle: _phone ?? l10n.noPhoneAvailable,
                      icon: Icons.sms_rounded,
                      isVerified: _phoneVerified,
                      controller: _phoneCodeController,
                      hintText: l10n.enterSmsCode,
                      verifyLabel: l10n.verifyPhone,
                      resendLabel: l10n.actionResend,
                      onVerify: _verifyPhone,
                      onResend: _sendPhoneCode,
                      isVerifying: _isVerifyingPhone,
                      isResending: _isSendingPhoneCode,
                    ),
                    const SizedBox(height: 28),
                    if (allVerified)
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _goToDashboard,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.successColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 22),
                          label: Text(l10n.actionContinue),
                        ),
                      )
                    else
                      SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _goToDashboard,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                AuthScreenColors.textPrimaryOf(context),
                            backgroundColor:
                                AuthScreenColors.surfaceOf(context),
                            side: BorderSide(
                              color: AuthScreenColors.surfaceBorderOf(context),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(l10n.actionSkip),
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
    final base = HomeColors.surfaceElevatedOf(context);
    final highlight = HomeColors.surfaceOf(context);

    Widget block(double height, {double? width, double radius = 16}) {
      return Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(72, width: 72, radius: 36),
          const SizedBox(height: 22),
          block(28, width: 220, radius: 10),
          const SizedBox(height: 12),
          block(14, radius: 8),
          const SizedBox(height: 24),
          block(230, radius: 24),
          const SizedBox(height: 16),
          block(230, radius: 24),
          const SizedBox(height: 28),
          block(56, radius: 18),
        ],
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

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: HomeColors.violetTintOf(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: HomeColors.violetOf(context),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AuthScreenColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 20),
          AuthGradientButton(
            label: l10n.actionRetry,
            showArrow: false,
            onPressed: onRetry,
          ),
        ],
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
  });

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final accent = isVerified ? AppColors.successColor : authIndigoOf(context);
    final tint = isVerified
        ? AppColors.successColor.withValues(alpha: 0.12)
        : authIndigoTintOf(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: isVerified
            ? Border.all(
                color: AppColors.successColor.withValues(alpha: 0.45),
                width: 1.4,
              )
            : (dark ? Border.all(color: HomeColors.borderOf(context)) : null),
        boxShadow: AppColors.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isVerified ? Icons.check_circle_rounded : icon,
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: HomeColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: HomeColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                const StatusChip(status: 'completed'),
              ],
            ],
          ),
          if (!isVerified) ...[
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HomeColors.textPrimaryOf(context),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
              ),
              decoration: authFieldDecoration(context, hint: hintText).copyWith(
                hintStyle: TextStyle(
                  color: AuthScreenColors.textMutedOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
                prefixIcon: const Icon(Icons.pin_rounded, size: 22),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isResending ? null : onResend,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: authIndigoOf(context),
                        side: BorderSide(
                          color: authIndigoOf(context).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: isResending
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: authIndigoOf(context),
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        resendLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: isVerifying ? null : onVerify,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandOrange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.brandOrange.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: isVerifying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              verifyLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
