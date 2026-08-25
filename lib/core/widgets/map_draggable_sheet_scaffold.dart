import 'package:flutter/material.dart';

/// Standard top inset for floating controls on map screens (below status bar).
/// Set [includeStatusBarInset] to false when the map is embedded inside a parent
/// [SafeArea] (e.g. home tab) so overlays sit near the top of the map area.
double mapOverlayTop(
  BuildContext context, {
  bool includeStatusBarInset = true,
}) =>
    (includeStatusBarInset ? MediaQuery.paddingOf(context).top : 0) + 8;

/// Full-bleed map with a [DraggableScrollableSheet] floating on top.
/// The map fills the body; use [onSheetLayoutChanged] / [sheetBottomInset]
/// for [GoogleMap.padding] so content isn't hidden under the sheet.
class MapDraggableSheetScaffold extends StatefulWidget {
  const MapDraggableSheetScaffold({
    super.key,
    required this.map,
    required this.sheetBuilder,
    this.mapOverlays = const [],
    required this.initialChildSize,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.85,
    this.onSheetLayoutChanged,
    this.backgroundColor,
  });

  final Widget map;
  final Widget Function(BuildContext context, ScrollController scrollController)
      sheetBuilder;
  final List<Widget> mapOverlays;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  /// Called when the sheet extent or available body height changes.
  final void Function(double extent, double bodyHeight)? onSheetLayoutChanged;
  final Color? backgroundColor;

  /// Bottom inset (px) covered by the sheet — useful for [GoogleMap.padding].
  static double sheetBottomInset(double bodyHeight, double sheetExtent) {
    return bodyHeight * sheetExtent;
  }

  @override
  State<MapDraggableSheetScaffold> createState() =>
      _MapDraggableSheetScaffoldState();
}

class _MapDraggableSheetScaffoldState extends State<MapDraggableSheetScaffold> {
  late double _sheetExtent;
  double _bodyHeight = 0;

  @override
  void initState() {
    super.initState();
    _sheetExtent = widget.initialChildSize;
  }

  @override
  void didUpdateWidget(MapDraggableSheetScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialChildSize != widget.initialChildSize) {
      _sheetExtent = widget.initialChildSize;
      _notifyLayout();
    }
  }

  void _notifyLayout() {
    if (_bodyHeight <= 0) return;
    widget.onSheetLayoutChanged?.call(_sheetExtent, _bodyHeight);
  }

  bool _onSheetNotification(DraggableScrollableNotification notification) {
    final extent = notification.extent;
    if ((extent - _sheetExtent).abs() > 0.001) {
      setState(() => _sheetExtent = extent);
      _notifyLayout();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: widget.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bodyHeight = constraints.maxHeight;
          if (_bodyHeight != bodyHeight) {
            _bodyHeight = bodyHeight;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _notifyLayout();
            });
          }
          return NotificationListener<DraggableScrollableNotification>(
            onNotification: _onSheetNotification,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.map,
                      ...widget.mapOverlays,
                    ],
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: widget.initialChildSize,
                  minChildSize: widget.minChildSize,
                  maxChildSize: widget.maxChildSize,
                  builder: widget.sheetBuilder,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Drag handle bar shown at the top of draggable sheet content.
class MapSheetDragHandle extends StatelessWidget {
  const MapSheetDragHandle({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final handleColor =
        color ?? Theme.of(context).colorScheme.outlineVariant;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: handleColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
