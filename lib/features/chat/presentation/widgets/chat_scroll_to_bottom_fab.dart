import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class ChatScrollToBottomFab extends StatelessWidget {
  final VoidCallback onPressed;
  final int newMessageCount;

  const ChatScrollToBottomFab({
    super.key,
    required this.onPressed,
    this.newMessageCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              if (newMessageCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      newMessageCount > 9 ? '9+' : '$newMessageCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.lightOnPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
