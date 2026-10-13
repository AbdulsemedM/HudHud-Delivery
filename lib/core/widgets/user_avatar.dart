import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

/// Circular user avatar. Shows the user's initial (when [name] is given) or a
/// person icon on a soft brand tint when no image is available.
/// Never uses a bundled default profile photo.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
    this.name,
  });

  final String? imageUrl;
  final String? localImagePath;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  /// Optional display name; its first letter is shown in the placeholder.
  final String? name;

  double get _size => radius * 2;

  bool get _hasLocalImage =>
      localImagePath != null && localImagePath!.isNotEmpty;

  bool get _hasNetworkImage =>
      imageUrl != null && imageUrl!.isNotEmpty && imageUrl!.startsWith('http');

  String? get _initial {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return null;
    return n.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (dark ? AppColors.indigoTintDark : AppColors.indigoTint);
    final fg = iconColor ??
        (backgroundColor != null
            ? Colors.white
            : (dark ? AppColors.brandIndigoBright : AppColors.brandIndigo));

    Widget placeholder() {
      final initial = _initial;
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: initial != null
            ? Text(
                initial,
                style: TextStyle(
                  fontSize: radius * 0.9,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  height: 1,
                ),
              )
            : Icon(Icons.person_rounded, size: radius * 1.15, color: fg),
      );
    }

    if (_hasLocalImage) {
      return ClipOval(
        child: Image.file(
          File(localImagePath!),
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder(),
        ),
      );
    }

    if (_hasNetworkImage) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSync) {
            if (wasSync || frame != null) return child;
            return placeholder();
          },
          errorBuilder: (_, __, ___) => placeholder(),
        ),
      );
    }

    return placeholder();
  }
}
