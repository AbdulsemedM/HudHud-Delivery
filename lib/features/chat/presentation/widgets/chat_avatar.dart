import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ChatAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool showUnreadRing;

  const ChatAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 56,
    this.showUnreadRing = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final scheme = Theme.of(context).colorScheme;

    Widget avatar;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(initials, scheme),
        ),
      );
    } else {
      avatar = _fallback(initials, scheme);
    }

    if (!showUnreadRing) return avatar;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.secondary, width: 2),
      ),
      child: avatar,
    );
  }

  Widget _fallback(String initials, ColorScheme scheme) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.primary,
          fontSize: size * 0.32,
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
