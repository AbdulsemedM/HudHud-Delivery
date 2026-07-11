import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/chat/presentation/theme/chat_theme.dart';
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
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
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
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.pendingAttachmentPaths.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              itemCount: widget.pendingAttachmentPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final path = widget.pendingAttachmentPaths[index];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppColors.r10),
                      child: Image.file(
                        File(path),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.insert_drive_file,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: GestureDetector(
                        onTap: () => widget.onRemoveAttachment(index),
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: scheme.error,
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.chatRecording,
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: chatTheme.composerBackground,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: 10 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.textOnly)
                _CircleIconButton(
                  icon: Icons.add_rounded,
                  onPressed: widget.isSending ? null : widget.onAttach,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkInputFill
                        : AppColors.lightInputFill,
                    borderRadius: BorderRadius.circular(AppColors.rFull),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkInputBorder
                          : AppColors.lightInputBorder,
                    ),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: l10n.chatTypeMessage,
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.lightTextHint,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.isSending)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
                    ),
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
                  child: _CircleIconButton(
                    icon: _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    onPressed: () async {
                      await _startRecording();
                      await Future.delayed(const Duration(seconds: 1));
                      if (_isRecording) await _stopRecording();
                    },
                    backgroundColor: _isRecording
                        ? scheme.errorContainer
                        : scheme.surfaceContainerHighest,
                    iconColor: _isRecording ? scheme.error : scheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: iconColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SendButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryColor,
      elevation: 2,
      shadowColor: AppColors.primaryColor.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
