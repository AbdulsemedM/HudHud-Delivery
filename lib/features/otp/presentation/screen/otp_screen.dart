import 'package:flutter/material.dart';
import '../widgets/otp_widget.dart';
import '../../../../core/theme/app_colors.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final GlobalKey<_OtpInputFieldsState> _otpInputKey =
      GlobalKey<_OtpInputFieldsState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // Logo
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HUDHUD',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      Text(
                        ' delivery',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Phone Graphic
                    _PhoneGraphic(),
                    const SizedBox(height: 30),
                    // Verification Title
                    Text(
                      'Verification',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      'We have sent you a verification code to ${widget.phoneNumber}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // OTP Input Fields
                    OtpInputFields(
                      key: _otpInputKey,
                      onCompleted: (otp) {
                        // TODO: Implement OTP verification
                        print('OTP entered: $otp');
                      },
                    ),
                    const SizedBox(height: 24),
                    // Resend Code Timer
                    OtpResendTimer(),
                  ],
                ),
              ),
            ),
            // Custom Numeric Keyboard
            OtpNumericKeyboard(
              otpInputFieldsState: _otpInputKey.currentState,
            ),
          ],
        ),
      ),
    );
  }
}

// Phone Graphic Widget
class _PhoneGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.grey[300]!, width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      '08:22',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Wednesday 29 September',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // WhatsApp Message Bubble
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green[300]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.green[600],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'WHATSAPP',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Authenticate Your OTP is 45880\nPlease provide the OTP sent to\n(***) ***1234',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[800],
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


