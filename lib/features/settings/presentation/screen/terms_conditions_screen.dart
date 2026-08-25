import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileDarkPage(
      title: 'Terms & Conditions',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegalSection(
              title: 'Terms of Service',
              content:
                  'By using HudHud Delivery you agree to follow our service rules, '
                  'pay for completed orders and rides, and provide accurate account '
                  'and delivery information. Misuse of the platform may result in '
                  'account suspension.',
            ),
            SizedBox(height: 24),
            _LegalSection(
              title: 'Privacy Policy',
              content:
                  'We collect account, location, and order information needed to '
                  'provide delivery and taxi services. Contact details and trip data '
                  'are shared with assigned drivers or couriers only as needed to '
                  'complete your request.',
            ),
            SizedBox(height: 24),
            _LegalSection(
              title: 'Contact',
              content:
                  'For the full legal terms or privacy questions, contact HudHud '
                  'Delivery support through the app Help & Support section.',
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String content;

  const _LegalSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthScreenColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthScreenColors.surfaceBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AuthScreenColors.orange,
            ),
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              height: 1.6,
              color: AuthScreenColors.textMutedOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
