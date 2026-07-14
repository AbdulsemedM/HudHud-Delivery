import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/utils/media_url_util.dart';

/// Loads a network image, trying original/alternate candidates when the first URL fails.
class FallbackNetworkImage extends StatefulWidget {
  const FallbackNetworkImage({
    super.key,
    required this.url,
    this.urls,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String url;
  final Map<dynamic, dynamic>? urls;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext context)? errorBuilder;

  @override
  State<FallbackNetworkImage> createState() => _FallbackNetworkImageState();
}

class _FallbackNetworkImageState extends State<FallbackNetworkImage> {
  late List<String> _candidates;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _resetCandidates();
  }

  @override
  void didUpdateWidget(covariant FallbackNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.urls != widget.urls) {
      _resetCandidates();
    }
  }

  void _resetCandidates() {
    _candidates = vendorMediaUrlCandidates(path: widget.url, urls: widget.urls);
    if (_candidates.isEmpty && widget.url.trim().isNotEmpty) {
      _candidates = [widget.url.trim()];
    }
    _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty || _index >= _candidates.length) {
      return widget.errorBuilder?.call(context) ?? const SizedBox.shrink();
    }

    return Image.network(
      _candidates[_index],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        if (_index + 1 < _candidates.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _index++);
          });
          return const SizedBox.shrink();
        }
        return widget.errorBuilder?.call(context) ?? const SizedBox.shrink();
      },
    );
  }
}
