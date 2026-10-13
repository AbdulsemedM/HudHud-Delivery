import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import '../widgets/otp_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/theme/home_colors.dart';
import '../../../login/presentation/widgets/auth_ui.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<OtpInputFieldsState> _otpInputKey =
      GlobalKey<OtpInputFieldsState>();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: HomeColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: HomeColors.backgroundOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            size: 26,
            color: HomeColors.textPrimaryOf(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      AuthHeading(
                        icon: Icons.sms_rounded,
                        center: true,
                        title: l10n.verificationCodeLabel,
                        subtitle: l10n.verifyPhoneBody(widget.phoneNumber),
                      ),
                      const SizedBox(height: AppColors.spaceXL),
                      OtpInputFields(
                        key: _otpInputKey,
                        onCompleted: (otp) {
                          // TODO: Implement OTP verification
                          debugPrint('OTP entered: $otp');
                        },
                      ),
                      const SizedBox(height: AppColors.spaceLG),
                      const OtpResendTimer(),
                    ],
                  ),
                ),
              ),
            ),
            OtpNumericKeyboard(
              otpInputFieldsState: _otpInputKey.currentState,
            ),
          ],
        ),
      ),
    );
  }
}
