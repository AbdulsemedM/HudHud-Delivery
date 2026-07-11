import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

/// Circular user avatar. Shows a person icon when no image is available.
/// Never uses a bundled default profile photo.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
  });

  final String? imageUrl;
  final String? localImagePath;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  double get _size => radius * 2;

  bool get _hasLocalImage =>
      localImagePath != null && localImagePath!.isNotEmpty;

  bool get _hasNetworkImage =>
      imageUrl != null && imageUrl!.isNotEmpty && imageUrl!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primaryColor;
    final fg = iconColor ?? Colors.white;

    Widget placeholder() => Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.person, size: radius * 1.1, color: fg),
        );

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
          errorBuilder: (_, __, ___) => placeholder(),
        ),
      );
    }

    return placeholder();
  }
}
