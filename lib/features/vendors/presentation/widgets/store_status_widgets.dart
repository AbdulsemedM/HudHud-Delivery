import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/vendors/data/models/store_status.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// `08:30` in device local time (24-hour, locale-independent digits so it
/// reads the same in every app language, including RTL Arabic).
String formatStoreTime(DateTime at) {
  final local = at.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// When the store opens / is back: `Opens 08:30`, `Opens tomorrow 08:30`,
/// `Opens 24/12 08:30`, `Back at 14:15`; null when the server gave no time.
String? storeStatusWhenLabel(
  AppLocalizations l10n,
  StoreStatus status, {
  DateTime? now,
}) {
  final current = (now ?? DateTime.now()).toLocal();
  if (status.isBusy) {
    final resumes = status.resumesAt;
    return resumes == null
        ? null
        : l10n.p12StoreBackAt(formatStoreTime(resumes));
  }
  if (!status.isClosed) return null;
  final opens = status.opensAt?.toLocal();
  if (opens == null) return status.isHoliday ? l10n.p12StoreClosedToday : null;
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(opens.year, opens.month, opens.day);
  final days = day.difference(today).inDays;
  final time = formatStoreTime(opens);
  if (days <= 0) return l10n.p12StoreOpensAt(time);
  if (days == 1) return l10n.p12StoreOpensTomorrowAt(time);
  return l10n.p12StoreOpensAt('${opens.day}/${opens.month} $time');
}

/// Short state word: Open / Closed / Busy.
String storeStateLabel(AppLocalizations l10n, StoreStatus status) {
  switch (status.state) {
    case StoreState.open:
      return l10n.p12StoreOpen;
    case StoreState.busy:
      return l10n.p12StoreBusy;
    case StoreState.closed:
      return l10n.p12StoreClosed;
  }
}

/// One line for chips and cards: `Closed · Opens tomorrow 08:30`.
String storeStatusLine(
  AppLocalizations l10n,
  StoreStatus status, {
  DateTime? now,
}) {
  final when = storeStatusWhenLabel(l10n, status, now: now);
  final state = storeStateLabel(l10n, status);
  return when == null ? state : '$state · $when';
}

/// Sentence for snackbars / dialogs when an order is refused because the
/// store is closed or busy.
String storeUnavailableMessage(
  AppLocalizations l10n,
  StoreStatus? status, {
  bool busy = false,
  DateTime? now,
}) {
  final isBusy = status?.isBusy ?? busy;
  final base = isBusy ? l10n.p12ErrStoreBusy : l10n.p12ErrStoreClosed;
  if (status == null) return base;
  final when = storeStatusWhenLabel(l10n, status, now: now);
  return when == null ? base : '$base $when.';
}

/// Compact pill for store cards and the store header (hidden when open).
class StoreStatusPill extends StatelessWidget {
  const StoreStatusPill({
    super.key,
    required this.status,
    this.compact = false,
    this.now,
  });

  final StoreStatus status;

  /// State word only (small cards); otherwise state plus opening time.
  final bool compact;

  /// Clock override for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (status.acceptingOrders) return const SizedBox.shrink();
    final l10n = context.l10n;
    final busy = status.isBusy;
    final background = busy ? const Color(0xFFB45309) : const Color(0xFF374151);
    final label = compact
        ? storeStateLabel(l10n, status)
        : storeStatusLine(l10n, status, now: now);
    return Semantics(
      label: storeStatusLine(l10n, status, now: now),
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('store_status_pill'),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 3 : 6,
        ),
        decoration: BoxDecoration(
          color: background.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              busy ? Icons.hourglass_top_rounded : Icons.schedule_rounded,
              size: compact ? 12 : 14,
              color: Colors.white,
            ),
            SizedBox(width: compact ? 4 : 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width notice on the store page and at checkout: why ordering is off
/// and when it comes back. Hidden while the store is open.
class StoreStatusBanner extends StatelessWidget {
  const StoreStatusBanner({super.key, required this.status, this.now});

  final StoreStatus status;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (status.acceptingOrders) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final when = storeStatusWhenLabel(l10n, status, now: now);
    final body =
        status.isBusy ? l10n.p12StoreBusyBanner : l10n.p12StoreClosedBanner;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('store_status_banner'),
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              status.isBusy
                  ? Icons.hourglass_top_rounded
                  : Icons.storefront_outlined,
              color: colorScheme.onErrorContainer,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    when == null
                        ? storeStateLabel(l10n, status)
                        : '${storeStateLabel(l10n, status)} · $when',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontSize: 13.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
