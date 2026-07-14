import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileDarkPage(
      title: 'Terms & Conditions',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClauseSection(
              clauseNumber: 1,
              content:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Viverra condimentum eget purus in. Consectetur eget id morbi amet amet, in. Ipsum viverra pretium tellus neque. Ullamcorper suspendisse aenean leo pharetra in sit semper et. Amet quam placerat sem.',
            ),
            SizedBox(height: 24),
            _ClauseSection(
              clauseNumber: 2,
              content:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Viverra condimentum eget purus in. Consectetur eget id morbi amet amet, in. Ipsum viverra pretium tellus neque. Ullamcorper suspendisse aenean leo pharetra in sit semper et. Amet quam placerat sem.',
            ),
            SizedBox(height: 24),
            _ClauseSection(
              clauseNumber: 3,
              content:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Viverra condimentum eget purus in. Consectetur eget id morbi amet amet, in. Ipsum viverra pretium tellus neque. Ullamcorper suspendisse aenean leo pharetra in sit semper et. Amet quam placerat sem.',
            ),
            SizedBox(height: 24),
            _ClauseSection(
              clauseNumber: 4,
              content:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Viverra condimentum eget purus in. Consectetur eget id morbi amet amet, in. Ipsum viverra pretium tellus neque. Ullamcorper suspendisse aenean leo pharetra in sit semper et. Amet quam placerat sem.',
            ),
            SizedBox(height: 24),
            _ClauseSection(
              clauseNumber: 5,
              content:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Viverra condimentum eget purus in. Consectetur eget id morbi amet amet, in. Ipsum viverra pretium tellus neque. Ullamcorper suspendisse aenean leo pharetra in sit semper et. Amet quam placerat sem.',
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ClauseSection extends StatelessWidget {
  final int clauseNumber;
  final String content;

  const _ClauseSection({
    required this.clauseNumber,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthScreenColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthScreenColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clause $clauseNumber',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AuthScreenColors.orange,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              height: 1.6,
              color: AuthScreenColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
