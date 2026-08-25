import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/config/support_config.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileDarkPage(
      title: l10n.chatSupportTitle,
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
