import 'dart:async';
import 'dart:io';

import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/features/chat/presentation/theme/chat_theme.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:record/record.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isEditing;
  final VoidCallback onSendText;
  final VoidCallback onAttach;
  final void Function(String path) onAudioRecorded;
  final List<String> pendingAttachmentPaths;
  final void Function(int index) onRemoveAttachment;
  final bool textOnly;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.isEditing,
    required this.onSendText,
    required this.onAttach,
    required this.onAudioRecorded,
    this.pendingAttachmentPaths = const [],
    required this.onRemoveAttachment,
    this.textOnly = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;
    final dir = Directory.systemTemp;
    final path =
        '${dir.path}/chat_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (!cancel && path != null && File(path).existsSync()) {
      widget.onAudioRecorded(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatTheme = ChatTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.pendingAttachmentPaths.isNotEmpty)
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.pendingAttachmentPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final path = widget.pendingAttachmentPaths[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(path),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.insert_drive_file),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => widget.onRemoveAttachment(index),
                        child: const CircleAvatar(
                          radius: 10,
                          child: Icon(Icons.close, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              l10n.chatRecording,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(
              chatTheme.composerBackground.withValues(alpha: 0.1),
              BlendMode.srcOver,
            ),
            child: Container(
              color: chatTheme.composerBackground,
              padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: 8 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!widget.textOnly)
                    IconButton(
                      onPressed: widget.isSending ? null : widget.onAttach,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.chatTypeMessage,
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (widget.isSending)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_hasText || widget.isEditing)
                    _SendButton(onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onSendText();
                    })
                  else if (!widget.textOnly)
                    GestureDetector(
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                      onLongPressCancel: () => _stopRecording(cancel: true),
                      child: IconButton(
                        onPressed: () async {
                          await _startRecording();
                          await Future.delayed(const Duration(seconds: 1));
                          if (_isRecording) await _stopRecording();
                        },
                        icon: Icon(
                          _isRecording ? Icons.stop_circle : Icons.mic_rounded,
                          color: _isRecording
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SendButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.send_rounded, color: AppColors.lightOnPrimary, size: 22),
        ),
      ),
    );
  }
}
