import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

class AttachmentPickerResult {
  final AttachmentPickerAction action;
  final List<String> filePaths;

  const AttachmentPickerResult({
    required this.action,
    this.filePaths = const [],
  });
}

enum AttachmentPickerAction { image, file, location, audio }

Future<AttachmentPickerResult?> showAttachmentPickerSheet(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;
  final action = await showModalBottomSheet<AttachmentPickerAction>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _AttachmentTile(
                icon: Icons.photo_library_rounded,
                label: l10n.chatAttachImage,
                color: Colors.purple,
                onTap: () =>
                    Navigator.pop(context, AttachmentPickerAction.image),
              ),
              _AttachmentTile(
                icon: Icons.insert_drive_file_rounded,
                label: l10n.chatAttachFile,
                color: Colors.blue,
                onTap: () =>
                    Navigator.pop(context, AttachmentPickerAction.file),
              ),
              _AttachmentTile(
                icon: Icons.location_on_rounded,
                label: l10n.chatShareLocation,
                color: Colors.green,
                onTap: () =>
                    Navigator.pop(context, AttachmentPickerAction.location),
              ),
              _AttachmentTile(
                icon: Icons.mic_rounded,
                label: l10n.chatAttachAudio,
                color: Colors.orange,
                onTap: () =>
                    Navigator.pop(context, AttachmentPickerAction.audio),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (action == null || !context.mounted) return null;

  switch (action) {
    case AttachmentPickerAction.image:
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return null;
      return AttachmentPickerResult(
        action: action,
        filePaths: images.map((e) => e.path).whereType<String>().toList(),
      );
    case AttachmentPickerAction.file:
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null || result.files.isEmpty) return null;
      final paths = result.files
          .map((f) => f.path)
          .whereType<String>()
          .where((p) => File(p).existsSync())
          .toList();
      if (paths.isEmpty) return null;
      return AttachmentPickerResult(action: action, filePaths: paths);
    case AttachmentPickerAction.location:
    case AttachmentPickerAction.audio:
      return AttachmentPickerResult(action: action);
  }
}

class _AttachmentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
