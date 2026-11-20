import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/orders/data/providers/orders_data_provider.dart';

/// The 4-digit code to read out to the driver at the door.
///
/// WHY IT IS FETCHED AND NOT PUSHED. The code is never in a notification
/// payload: push text shows on a lock screen and FCM data is readable by
/// anything on the device that can read it. The `delivery_code_ready` push
/// only says to look, and this authenticated read is how the app gets the
/// digits.
///
/// That also makes the push optional rather than load-bearing. With
/// notifications off, throttled or failed, the code still appears here - which
/// is the property that made showing the code beat texting it. The Telegram
/// Gateway has no balance endpoint and falls back to SMS silently, so a sent
/// code can simply never arrive and leave the driver stuck at the door.
///
/// Renders NOTHING until the driver asks for a code, which is most of a
/// delivery. `state: not_issued` is the normal early answer and not an error,
/// so a failed poll is silent too - a red box on the tracking screen would be
/// alarming and useless, since there is nothing the customer can do.
class DeliveryCodeCard extends StatefulWidget {
  const DeliveryCodeCard({
    super.key,
    required this.orderId,
    this.fetchCode,
    this.pollInterval = const Duration(seconds: 12),
  });

  final int orderId;

  /// Overridable for tests. A function rather than the whole provider, so a
  /// test does not have to build an ApiService - whose constructor creates a
  /// Dio client - just to answer one endpoint.
  final Future<Map<String, dynamic>> Function(int orderId)? fetchCode;

  final Duration pollInterval;

  @override
  State<DeliveryCodeCard> createState() => _DeliveryCodeCardState();
}

class _DeliveryCodeCardState extends State<DeliveryCodeCard>
    with WidgetsBindingObserver {
  String? _code;
  Timer? _timer;
  bool _fetching = false;

  Future<Map<String, dynamic>> Function(int) get _fetchCode =>
      widget.fetchCode ??
      OrdersDataProvider(apiService: ApiService.instance).getDeliveryCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_fetch());
    _timer = Timer.periodic(widget.pollInterval, (_) => unawaited(_fetch()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The customer most likely opened the app because the driver asked them
    // to, so check immediately rather than waiting out the interval.
    if (state == AppLifecycleState.resumed) unawaited(_fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_fetching || !mounted) return;
    _fetching = true;
    try {
      final res = await _fetchCode(widget.orderId);
      if (!mounted) return;

      final data = res['data'];
      final payload = data is Map ? data['data'] : null;
      final code = payload is Map ? payload['code']?.toString() : null;

      setState(() {
        _code = (code != null && code.isNotEmpty) ? code : null;
      });
    } catch (_) {
      // Silent on purpose. There is nothing the customer can do about a
      // failed poll, and the next tick retries.
    } finally {
      _fetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    if (code == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.deliveryCodeTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.deliveryCodePrompt,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Center(
            // Spaced out so it can be read aloud a digit at a time, at a door,
            // possibly in the dark.
            child: Text(
              code.split('').join('   '),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.deliveryCodeWarning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
