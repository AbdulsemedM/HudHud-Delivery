import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/easy_mode/voice_hint_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

/// Speaker control that reads [text] aloud (Easy Mode).
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.large = false,
  });

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.easySpeakHint;
    if (large) {
      return SizedBox(
        height: 56,
        child: OutlinedButton.icon(
          onPressed: text.trim().isEmpty
              ? null
              : () => VoiceHintService.instance.speak(text),
          icon: const Icon(Icons.volume_up_rounded, size: 28),
          label: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AuthScreenColors.orange,
            side: BorderSide(color: AuthScreenColors.orange),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: label,
      onPressed: text.trim().isEmpty
          ? null
          : () => VoiceHintService.instance.speak(text),
      icon: Icon(
        Icons.volume_up_rounded,
        color: HomeColors.violet,
        size: 28,
      ),
    );
  }
}
