import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/models/delivery_stop.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:latlong2/latlong.dart';

/// Drop-offs 2..N under the normal drop-off row of the classic booking
/// sheets. Stateless: the screen owns the list and the location picker.
///
/// Shows nothing when [maxExtraStops] is 0 (multi-stop switched off) or the
/// first drop-off is not chosen yet ([enabled] false).
class ExtraStopsEditor extends StatelessWidget {
  const ExtraStopsEditor({
    super.key,
    required this.stops,
    required this.maxExtraStops,
    required this.enabled,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onMove,
  });

  final List<DeliveryStopDraft> stops;
  final int maxExtraStops;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  /// (index, delta) — delta is -1 (up) or +1 (down).
  final void Function(int index, int delta) onMove;

  @override
  Widget build(BuildContext context) {
    if (maxExtraStops <= 0 || (!enabled && stops.isEmpty)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final canAdd = enabled && stops.length < maxExtraStops;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < stops.length; i++)
          _ExtraStopRow(
            number: i + 2,
            address: stops[i].location,
            canMoveUp: i > 0,
            canMoveDown: i < stops.length - 1,
            onTap: () => onEdit(i),
            onRemove: () => onRemove(i),
            onMoveUp: () => onMove(i, -1),
            onMoveDown: () => onMove(i, 1),
          ),
        if (canAdd)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_location_alt_rounded, size: 24),
                label: Text(
                  l10n.msAddStop,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HomeColors.violetOf(context),
                  side: BorderSide(
                    color: HomeColors.violetOf(context).withValues(alpha: 0.5),
                    width: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          )
        else if (enabled && stops.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              l10n.msMaxStopsReached(maxExtraStops + 1),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HomeColors.textMutedOf(context),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExtraStopRow extends StatelessWidget {
  const _ExtraStopRow({
    required this.number,
    required this.address,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onTap,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final int number;
  final String address;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final violet = HomeColors.violetOf(context);
    final muted = HomeColors.textMutedOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: AppColors.softShadow(context),
        ),
        child: Material(
          color: HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(color: HomeColors.borderOf(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(
                  children: [
                    StopNumberBadge(number: number),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.msStopLabel(number),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              color: HomeColors.textPrimaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canMoveUp || canMoveDown)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SmallIconButton(
                            icon: Icons.keyboard_arrow_up_rounded,
                            tooltip: l10n.msMoveStopUp,
                            color: violet,
                            onPressed: canMoveUp ? onMoveUp : null,
                          ),
                          _SmallIconButton(
                            icon: Icons.keyboard_arrow_down_rounded,
                            tooltip: l10n.msMoveStopDown,
                            color: violet,
                            onPressed: canMoveDown ? onMoveDown : null,
                          ),
                        ],
                      ),
                    IconButton(
                      tooltip: l10n.msRemoveStop,
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.errorColor,
                        size: 24,
                      ),
                      onPressed: onRemove,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 30),
      icon: Icon(icon, size: 26),
      color: color,
      disabledColor: HomeColors.textMutedOf(context).withValues(alpha: 0.35),
      onPressed: onPressed,
    );
  }
}

/// Round indigo tile with the stop number (stop list / summaries).
class StopNumberBadge extends StatelessWidget {
  const StopNumberBadge({super.key, required this.number, this.size = 48});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HomeColors.violetTintOf(context),
        borderRadius: BorderRadius.circular(size * 0.31),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: HomeColors.violetOf(context),
        ),
      ),
    );
  }
}

// ── Map helpers shared by the booking screens ────────────────────────────

gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

/// Indigo markers for drop-offs 2..N; the info window names the stop.
Set<gmaps.Marker> extraStopMarkers(
  List<DeliveryStopDraft> stops, {
  required String Function(int number) label,
}) {
  return {
    for (var i = 0; i < stops.length; i++)
      gmaps.Marker(
        markerId: gmaps.MarkerId('stop_${i + 2}'),
        position: _toG(stops[i].position),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(266.0),
        infoWindow: gmaps.InfoWindow(
          title: label(i + 2),
          snippet: stops[i].location,
        ),
      ),
  };
}

/// Bounds over [points]; null when fewer than two distinct points.
gmaps.LatLngBounds? boundsForPoints(List<LatLng> points) {
  if (points.length < 2) return null;
  var minLat = points.first.latitude, maxLat = minLat;
  var minLng = points.first.longitude, maxLng = minLng;
  for (final p in points.skip(1)) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  if ((maxLat - minLat).abs() < 1e-6 && (maxLng - minLng).abs() < 1e-6) {
    return null;
  }
  return gmaps.LatLngBounds(
    southwest: gmaps.LatLng(minLat, minLng),
    northeast: gmaps.LatLng(maxLat, maxLng),
  );
}

/// Moves item [index] by [delta] (±1) in a copy of [list].
List<T> movedListItem<T>(List<T> list, int index, int delta) {
  final target = index + delta;
  if (index < 0 ||
      index >= list.length ||
      target < 0 ||
      target >= list.length) {
    return list;
  }
  final copy = List<T>.of(list);
  final item = copy.removeAt(index);
  copy.insert(target, item);
  return copy;
}
