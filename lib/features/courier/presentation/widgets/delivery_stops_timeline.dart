import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/features/courier/data/models/delivery_stop.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Localized label for a [DeliveryStopStatus].
String deliveryStopStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case DeliveryStopStatus.enRoute:
      return l10n.msStopStatusEnRoute;
    case DeliveryStopStatus.arrived:
      return l10n.msStopStatusArrived;
    case DeliveryStopStatus.delivered:
      return l10n.msStopStatusDelivered;
    case DeliveryStopStatus.failed:
      return l10n.msStopStatusFailed;
    case DeliveryStopStatus.skipped:
      return l10n.msStopStatusSkipped;
    default:
      return l10n.msStopStatusPending;
  }
}

Color deliveryStopStatusColor(BuildContext context, DeliveryStop stop) {
  if (stop.isDelivered) return AppColors.successColor;
  if (stop.isFailed) return AppColors.errorColor;
  if (stop.status == DeliveryStopStatus.arrived ||
      stop.status == DeliveryStopStatus.enRoute) {
    return AppColors.infoColor;
  }
  return HomeColors.textMutedOf(context);
}

IconData _statusIcon(DeliveryStop stop) {
  if (stop.isDelivered) return Icons.check_circle_rounded;
  if (stop.isFailed) return Icons.cancel_rounded;
  if (stop.status == DeliveryStopStatus.arrived) {
    return Icons.where_to_vote_rounded;
  }
  if (stop.status == DeliveryStopStatus.enRoute) {
    return Icons.delivery_dining_rounded;
  }
  return Icons.location_on_rounded;
}

/// Small "N stops" pill for list rows / cards.
class DeliveryStopsCountBadge extends StatelessWidget {
  const DeliveryStopsCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final violet = HomeColors.violetOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: HomeColors.violetTintOf(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alt_route_rounded, size: 14, color: violet),
          const SizedBox(width: 4),
          Text(
            context.l10n.msStopsCount(count),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: violet,
            ),
          ),
        ],
      ),
    );
  }
}

/// Address to show in a one-line row for a multi-stop delivery: the stop
/// the courier is heading to, else the last stop. Null for single-drop.
String? multiStopRowAddress(Map<String, dynamic>? delivery) {
  final stops = parseDeliveryStops(delivery);
  if (stops.length < 2) return null;
  final stop = currentDeliveryStop(delivery, stops) ?? stops.last;
  return stop.location;
}

/// Vertical route: pickup → stop 1..N with per-stop status, receiver (tap
/// to call) and the stop's delivery code for the sender to share.
class DeliveryStopsTimeline extends StatelessWidget {
  const DeliveryStopsTimeline({
    super.key,
    required this.stops,
    this.pickupLocation,
    this.currentSequence,
    this.showHeader = true,
  });

  /// Builds from a delivery map; [stops] must have 2+ entries to be useful.
  factory DeliveryStopsTimeline.fromDelivery(
    Map<String, dynamic> delivery, {
    Key? key,
    bool showHeader = true,
  }) {
    final stops = parseDeliveryStops(delivery);
    return DeliveryStopsTimeline(
      key: key,
      stops: stops,
      pickupLocation: delivery['pickup_location']?.toString(),
      currentSequence: currentDeliveryStop(delivery, stops)?.sequence,
      showHeader: showHeader,
    );
  }

  final List<DeliveryStop> stops;
  final String? pickupLocation;
  final int? currentSequence;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final done = stops.where((s) => s.isDone).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Icon(Icons.alt_route_rounded,
                  color: HomeColors.violetOf(context), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.msRouteTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
              ),
              Text(
                l10n.msStopsProgress(done, stops.length),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stops.isEmpty ? 0 : done / stops.length,
              minHeight: 6,
              backgroundColor: HomeColors.borderOf(context),
              color: AppColors.successColor,
            ),
          ),
          const SizedBox(height: 16),
        ],
        _TimelineRow(
          icon: Icons.trip_origin_rounded,
          color: AppColors.brandIndigo,
          label: l10n.msPickupLabel,
          address: pickupLocation ?? '—',
          showConnector: stops.isNotEmpty,
          dimmed: false,
        ),
        for (var i = 0; i < stops.length; i++)
          _StopRow(
            stop: stops[i],
            isCurrent: stops[i].sequence == currentSequence,
            showConnector: i < stops.length - 1,
          ),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.isCurrent,
    required this.showConnector,
  });

  final DeliveryStop stop;
  final bool isCurrent;
  final bool showConnector;

  Future<void> _call(BuildContext context, String phone) async {
    final ok = await launchUrl(
      Uri(scheme: 'tel', path: phone),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      await Clipboard.setData(ClipboardData(text: phone));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = deliveryStopStatusColor(context, stop);
    final name = stop.receiverName?.trim();
    final phone = stop.receiverPhone?.trim();
    final code = stop.deliveryCode?.trim();
    final showCode =
        code != null && code.isNotEmpty && !stop.isDone;

    return _TimelineRow(
      icon: _statusIcon(stop),
      color: isCurrent ? AppColors.infoColor : color,
      label: l10n.msStopLabel(stop.sequence),
      address: stop.location ?? '—',
      showConnector: showConnector,
      highlighted: isCurrent,
      dimmed: stop.isDone,
      trailing: _StatusPill(
        label: deliveryStopStatusLabel(l10n, stop.status),
        color: color,
      ),
      extra: [
        if (name != null && name.isNotEmpty ||
            phone != null && phone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.person_rounded,
                    size: 18, color: HomeColors.textMutedOf(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      if (name != null && name.isNotEmpty) name,
                      if (phone != null && phone.isNotEmpty)
                        formatPhoneForDisplay(phone),
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: HomeColors.textSecondaryOf(context),
                    ),
                  ),
                ),
                if (phone != null && phone.isNotEmpty)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: phone,
                      onPressed: () => _call(context, phone),
                      icon: const Icon(Icons.call_rounded,
                          color: AppColors.successColor),
                    ),
                  ),
              ],
            ),
          ),
        if (showCode)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: HomeColors.violetTintOf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pin_rounded,
                    size: 20, color: HomeColors.violetOf(context)),
                const SizedBox(width: 8),
                Text(
                  l10n.msStopCode(code),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: HomeColors.violetOf(context),
                  ),
                ),
              ],
            ),
          ),
        if (stop.isFailed &&
            (stop.failureReason?.trim().isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              stop.failureReason!.trim(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.errorColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
    required this.showConnector,
    this.highlighted = false,
    this.dimmed = false,
    this.trailing,
    this.extra = const [],
  });

  final IconData icon;
  final Color color;
  final String label;
  final String address;
  final bool showConnector;
  final bool highlighted;
  final bool dimmed;
  final Widget? trailing;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final content = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: dark ? 0.22 : 0.12),
                    shape: BoxShape.circle,
                    border: highlighted
                        ? Border.all(color: color, width: 2)
                        : null,
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: HomeColors.borderOf(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: showConnector ? 16 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: HomeColors.textMutedOf(context),
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.textPrimaryOf(context),
                    ),
                  ),
                  ...extra,
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Opacity(opacity: dimmed ? 0.6 : 1, child: content);
  }
}
