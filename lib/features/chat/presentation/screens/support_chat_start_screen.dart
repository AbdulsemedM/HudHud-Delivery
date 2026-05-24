import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/chat/chat_bloc_provider.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatSupportTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.chatSupportSubject,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.chatSupportSubjectHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.chatCreateSupport),
            ),
          ],
        ),
      ),
    );
  }
}
