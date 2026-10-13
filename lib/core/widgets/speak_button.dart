import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/easy_mode/voice_hint_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

/// Speaker control that reads [text] aloud (Easy Mode).
///
/// Compact: a 48px round button with a soft brand-indigo tint.
/// Large: a full-width tinted pill with icon + "Listen" label.
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
    final accent = HomeColors.violetOf(context);
    final tint = HomeColors.violetTintOf(context);
    final enabled = text.trim().isNotEmpty;
    void speak() => VoiceHintService.instance.speak(text);

    if (large) {
      return SizedBox(
        height: 56,
        child: Material(
          color: tint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? speak : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volume_up_rounded, size: 26, color: accent),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: tint,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? speak : null,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.volume_up_rounded,
                  color: enabled ? accent : accent.withValues(alpha: 0.4),
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
