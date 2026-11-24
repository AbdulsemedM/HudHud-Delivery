import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/config/support_config.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/support_launcher.dart';
import 'package:hudhud_delivery/features/chat/chat_bloc_provider.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class SupportChatStartScreen extends StatefulWidget {
  const SupportChatStartScreen({super.key});

  @override
  State<SupportChatStartScreen> createState() => _SupportChatStartScreenState();
}

class _SupportChatStartScreenState extends State<SupportChatStartScreen> {
  final _subjectController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = createChatRepository();
      final result = await repo.createSupportConversation(subject);
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _callCenter() async {
    final ok = await launchSupportPhone();
    if (mounted && !ok) {
      AuthSnackBar.error(context, AppLocalizations.of(context)!.actionTryAgain);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileDarkPage(
      title: l10n.chatSupportTitle,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calling comes first: most customers would rather talk to the
            // call center on the short number than write their problem out.
            // Writing stays below for those who prefer it.
            _CallCenterCard(
              label: l10n.callSupport,
              number: SupportConfig.supportPhoneE164,
              onTap: _loading ? null : _callCenter,
            ),
            SizedBox(height: 28),
            Text(
              l10n.chatSupportSubject,
              style: TextStyle(
                color: AuthScreenColors.textPrimaryOf(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              maxLines: 3,
              style: TextStyle(color: AuthScreenColors.textPrimaryOf(context)),
              decoration: InputDecoration(
                hintText: l10n.chatSupportSubjectHint,
                hintStyle: TextStyle(color: AuthScreenColors.textSecondaryOf(context)),
                filled: true,
                fillColor: AuthScreenColors.surfaceOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AuthScreenColors.surfaceBorderOf(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AuthScreenColors.orange,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AuthScreenColors.orange,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : Text(l10n.chatCreateSupport),
            ),
            SizedBox(height: 28),
            Divider(color: AuthScreenColors.surfaceBorderOf(context)),
            SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      final ok = await launchSupportEmail();
                      if (context.mounted && !ok) {
                        AuthSnackBar.error(context, l10n.actionTryAgain);
                      }
                    },
              icon: Icon(Icons.email_outlined, size: 20),
              label: Text(l10n.settingsContactEmail),
              style: OutlinedButton.styleFrom(
                foregroundColor: AuthScreenColors.textPrimaryOf(context),
                side: BorderSide(color: AuthScreenColors.surfaceBorderOf(context)),
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            SizedBox(height: 8),
            Text(
              SupportConfig.supportEmail,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuthScreenColors.textSecondaryOf(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tap dials the call center; the short number is shown large so it can
/// also be read and dialled by hand.
class _CallCenterCard extends StatelessWidget {
  const _CallCenterCard({
    required this.label,
    required this.number,
    required this.onTap,
  });

  final String label;
  final String number;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.successColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.call_rounded, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      number,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
