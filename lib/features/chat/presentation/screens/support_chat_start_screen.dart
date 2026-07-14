import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/chat/chat_bloc_provider.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.chatSupportSubject,
              style: const TextStyle(
                color: AuthScreenColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              maxLines: 3,
              style: const TextStyle(color: AuthScreenColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.chatSupportSubjectHint,
                hintStyle: const TextStyle(color: AuthScreenColors.textSecondary),
                filled: true,
                fillColor: AuthScreenColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AuthScreenColors.surfaceBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AuthScreenColors.orange,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AuthScreenColors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(l10n.chatCreateSupport),
            ),
          ],
        ),
      ),
    );
  }
}
