import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

/// Cached network image with a quiet placeholder; never throws on bad URLs.
class GrowthNetworkImage extends StatelessWidget {
  const GrowthNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_outlined,
    this.memCacheWidth,
  });

  final String? url;
  final BoxFit fit;
  final IconData icon;

  /// Decode at a bounded size to keep memory low on entry-level phones.
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: HomeColors.surfaceElevatedOf(context),
      child: Center(
        child: Icon(icon, color: HomeColors.textMutedOf(context), size: 28),
      ),
    );
    final u = url?.trim();
    if (u == null || u.isEmpty) return placeholder;
    final uri = Uri.tryParse(u);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return placeholder;
    }
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}
