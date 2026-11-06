import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_payment_helper.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

import 'parcel_v2_models.dart';
import 'parcel_v2_repository.dart';

const List<String> kParcelDefaultCategories = [
  'document',
  'parcel',
  'food',
  'electronics',
  'clothes',
  'gift',
  'keys',
  'other',
];

/// "USD 2.40" — always the server currency, never an assumed ETB.
String formatParcelMoney(double amount, String? currency) {
  final value = amount.toStringAsFixed(2);
  final code = currency?.trim().toUpperCase() ?? '';
  return code.isEmpty ? value : '$code $value';
}

String parcelCategoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'document':
      return l10n.p10ParcelCategoryDocument;
    case 'food':
      return l10n.p10ParcelCategoryFood;
    case 'grocery':
      return l10n.p10ParcelCategoryGrocery;
    case 'electronics':
      return l10n.p10ParcelCategoryElectronics;
    case 'clothes':
      return l10n.p10ParcelCategoryClothes;
    case 'gift':
      return l10n.p10ParcelCategoryGift;
    case 'flowers':
      return l10n.p10ParcelCategoryFlowers;
    case 'keys':
      return l10n.p10ParcelCategoryKeys;
    case 'other':
      return l10n.p10ParcelCategoryOther;
    case 'parcel':
    default:
      return l10n.p10ParcelCategoryParcel;
  }
}

String parcelSizeLabel(AppLocalizations l10n, String size) {
  switch (size) {
    case 'medium':
      return l10n.p10ParcelSizeMedium;
    case 'large':
      return l10n.p10ParcelSizeLarge;
    case 'small':
    default:
      return l10n.p10ParcelSizeSmall;
  }
}

String parcelSizeHint(AppLocalizations l10n, String size) {
  switch (size) {
    case 'medium':
      return l10n.p10ParcelSizeMediumHint;
    case 'large':
      return l10n.p10ParcelSizeLargeHint;
    case 'small':
    default:
      return l10n.p10ParcelSizeSmallHint;
  }
}

IconData parcelVehicleIcon(String? vehicle) {
  switch (vehicle) {
    case 'car':
      return Icons.directions_car;
    case 'pickup':
      return Icons.local_shipping;
    case 'bajaj':
      return Icons.electric_rickshaw;
    case 'motorbike':
    default:
      return Icons.two_wheeler;
  }
}

class ParcelSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ParcelSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ParcelAddressTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? address;
  final String placeholder;
  final VoidCallback onTap;

  const ParcelAddressTile({
    super.key,
    required this.icon,
    required this.label,
    required this.address,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAddress = address != null && address!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    hasAddress ? address! : placeholder,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: hasAddress
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// Building / floor / apartment / landmark under an address.
class ParcelAddressDetailsFields extends StatelessWidget {
  final TextEditingController building;
  final TextEditingController floor;
  final TextEditingController apartment;
  final TextEditingController landmark;

  const ParcelAddressDetailsFields({
    super.key,
    required this.building,
    required this.floor,
    required this.apartment,
    required this.landmark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4),
      child: Column(
        children: [
          TextField(
            controller: building,
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.p10ParcelBuilding,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: floor,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: l10n.p10ParcelFloor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: apartment,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: l10n.p10ParcelApartment,
                  ),
                ),
              ),
            ],
          ),
          TextField(
            controller: landmark,
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.p10ParcelLandmark,
            ),
          ),
        ],
      ),
    );
  }
}

class ParcelCategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const ParcelCategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in categories)
          ChoiceChip(
            label: Text(parcelCategoryLabel(l10n, category)),
            selected: category == selected,
            onSelected: (_) => onSelected(category),
          ),
      ],
    );
  }
}

/// Small / medium / large with the vehicle the city uses for each size.
class ParcelSizeSelector extends StatelessWidget {
  final ParcelV2Config config;
  final String selected;
  final ValueChanged<String> onSelected;

  const ParcelSizeSelector({
    super.key,
    required this.config,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const sizes = ['small', 'medium', 'large'];
    return Row(
      children: [
        for (final size in sizes) ...[
          Expanded(
            child: Builder(
              builder: (context) {
                final option = config.sizeOption(size);
                final available = option?.available ?? size == 'small';
                final isSelected = size == selected;
                return Semantics(
                  selected: isSelected,
                  button: true,
                  enabled: available,
                  child: InkWell(
                    key: ValueKey('parcel_size_$size'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: available ? () => onSelected(size) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : theme.colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Opacity(
                        opacity: available ? 1 : 0.4,
                        child: Column(
                          children: [
                            Icon(parcelVehicleIcon(option?.vehicleType)),
                            const SizedBox(height: 4),
                            Text(
                              parcelSizeLabel(l10n, size),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              available
                                  ? parcelSizeHint(l10n, size)
                                  : l10n.p10ParcelSizeUnavailable,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (size != sizes.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class ParcelPaymentMethodPicker extends StatelessWidget {
  final List<String> methods;
  final String selected;
  final ValueChanged<String> onSelected;

  const ParcelPaymentMethodPicker({
    super.key,
    required this.methods,
    required this.selected,
    required this.onSelected,
  });

  String _label(AppLocalizations l10n, String method) {
    if (method == 'wallet') return l10n.p10ParcelPayWallet;
    if (method == 'cash') return l10n.p10ParcelPayCash;
    return formatPaymentMethodLabel(method);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final method in methods)
          ChoiceChip(
            label: Text(_label(l10n, method)),
            selected: method == selected,
            onSelected: (_) => onSelected(method),
          ),
      ],
    );
  }
}

/// Upfront price with the lock countdown.
class ParcelQuoteCard extends StatelessWidget {
  final ParcelQuote? quote;
  final bool loading;
  final String? error;
  final bool waitingForRoute;
  final VoidCallback onRefresh;

  const ParcelQuoteCard({
    super.key,
    required this.quote,
    required this.loading,
    required this.error,
    required this.waitingForRoute,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final q = quote;
    Widget content;
    if (waitingForRoute) {
      content = Text(l10n.p10ParcelFillRequired);
    } else if (loading) {
      content = Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(l10n.p10ParcelGettingPrice),
        ],
      );
    } else if (error != null) {
      content = Row(
        children: [
          Expanded(
            child: Text(
              error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          TextButton(onPressed: onRefresh, child: Text(l10n.p10ParcelRefreshPrice)),
        ],
      );
    } else if (q == null) {
      content = TextButton(
        onPressed: onRefresh,
        child: Text(l10n.p10ParcelRefreshPrice),
      );
    } else {
      final expired = q.isExpired();
      content = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.p10ParcelPrice, style: theme.textTheme.labelMedium),
                Text(
                  formatParcelMoney(q.amount, q.currency),
                  key: const ValueKey('parcel_quote_amount'),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  expired
                      ? l10n.p10ParcelPriceExpired
                      : l10n.p10ParcelPriceHeld(
                          formatQuoteCountdown(q.remaining()),
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: expired
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (q.vehicleType != null) Icon(parcelVehicleIcon(q.vehicleType)),
          if (expired)
            TextButton(
              onPressed: onRefresh,
              child: Text(l10n.p10ParcelRefreshPrice),
            ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: content,
    );
  }
}

class ParcelHandoverCodeView extends StatelessWidget {
  final String code;
  final String hint;

  const ParcelHandoverCodeView({
    super.key,
    required this.code,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orangeTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            l10n.p10ParcelHandoverCode,
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Semantics(
            label: code.split('').join(' '),
            child: Text(
              code,
              key: const ValueKey('parcel_handover_code'),
              style: const TextStyle(
                fontSize: 32,
                letterSpacing: 8,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

/// Parcel v2 extras on the finding / tracking screens: handover code, share
/// link and cancellation with the server fee. Renders nothing for legacy
/// (v1) deliveries or when the server has no parcel v2 endpoint.
class ParcelV2Panel extends StatefulWidget {
  final int? deliveryId;
  final bool allowCancel;

  /// Called after a successful cancel (e.g. go back home).
  final VoidCallback? onCancelled;
  final ParcelV2Repository? repository;

  const ParcelV2Panel({
    super.key,
    required this.deliveryId,
    this.allowCancel = true,
    this.onCancelled,
    this.repository,
  });

  @override
  State<ParcelV2Panel> createState() => _ParcelV2PanelState();
}

class _ParcelV2PanelState extends State<ParcelV2Panel> {
  late final ParcelV2Repository _repo;
  ParcelV2Parcel? _parcel;
  Timer? _poll;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ParcelV2Repository();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.deliveryId;
    if (id == null) return;
    final result = await _repo.show(id);
    if (!mounted) return;
    final parcel = result.value;
    if (parcel == null || !parcel.isV2) {
      // Legacy parcel or older backend: nothing to show, stop polling.
      _poll?.cancel();
      return;
    }
    setState(() => _parcel = parcel);
    if (parcel.isTerminal) _poll?.cancel();
  }

  Future<void> _cancel(ParcelV2Parcel parcel) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final preview = parcel.cancellation;
    final fee = preview?.fee ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.p10ParcelCancel),
        content: Text(
          fee <= 0
              ? l10n.p10ParcelCancelFree
              : (preview?.chargedToWalletOrBalance ?? false)
                  ? l10n.p11ParcelCancelCashFee(
                      formatParcelMoney(
                        fee,
                        preview?.currency ?? parcel.currency,
                      ),
                    )
                  : l10n.p10ParcelCancelFee(
                      formatParcelMoney(
                        fee,
                        preview?.currency ?? parcel.currency,
                      ),
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.actionYesCancel,
              style: const TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    final result = await _repo.cancel(
      parcel.id,
      reason: l10n.p10ParcelCancelReason,
      acceptFee: fee,
    );
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (!result.ok) {
      if (result.errorKind == ParcelErrorKind.feeConfirmation) {
        await _load();
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message ?? l10n.p10ParcelSomethingWrong),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.p10ParcelCancelled)));
    await _load();
    widget.onCancelled?.call();
  }

  @override
  Widget build(BuildContext context) {
    final parcel = _parcel;
    if (parcel == null || parcel.isTerminal) return const SizedBox.shrink();
    final l10n = context.l10n;
    final canCancel = widget.allowCancel &&
        (parcel.cancellation?.canCancel ?? false);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parcel.paysAtPickup) ...[
            ParcelPayAtPickupNote(
              amount: parcel.amount,
              currency: parcel.currency,
              collected: parcel.collectedAtPickup,
            ),
            const SizedBox(height: 8),
          ],
          if (parcel.isMultiStop)
            ParcelStopsList(
              stops: parcel.stops,
              currentStop: parcel.currentStop,
            )
          else if (parcel.handoverCode != null && !parcel.handoverVerified)
            ParcelHandoverCodeView(
              code: parcel.handoverCode!,
              hint: l10n.p10ParcelHandoverHint,
            ),
          if (parcel.etaMinutes != null && parcel.etaMinutes! > 0) ...[
            const SizedBox(height: 8),
            Text(
              l10n.p10ParcelEta(parcel.etaMinutes.toString()),
              textAlign: TextAlign.center,
            ),
          ],
          Row(
            children: [
              if (parcel.trackingUrl != null)
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.share),
                    label: Text(l10n.p10ParcelShareTracking),
                    onPressed: () => Share.share(
                      l10n.p10ParcelTrackingShareText(parcel.trackingUrl!),
                    ),
                  ),
                ),
              if (canCancel)
                Expanded(
                  child: TextButton(
                    onPressed: _cancelling ? null : () => _cancel(parcel),
                    child: Text(
                      l10n.p10ParcelCancel,
                      style: const TextStyle(color: AppColors.errorColor),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Phase 11 ───────────────────────────────────────────────────────────

String parcelStopStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case ParcelStopStatus.arrived:
      return l10n.p11ParcelStopArrived;
    case ParcelStopStatus.delivered:
      return l10n.p11ParcelStopDelivered;
    case ParcelStopStatus.failed:
      return l10n.p11ParcelStopFailed;
    case ParcelStopStatus.returned:
      return l10n.p11ParcelStopReturned;
    case ParcelStopStatus.pending:
    default:
      return l10n.p11ParcelStopPending;
  }
}

/// "Stop 2" header with reorder / remove actions for the booking form.
class ParcelStopHeader extends StatelessWidget {
  final int number;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onRemove;

  const ParcelStopHeader({
    super.key,
    required this.number,
    this.onMoveUp,
    this.onMoveDown,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.p11ParcelStopN(number.toString()),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (onMoveUp != null)
          IconButton(
            key: ValueKey('parcel_stop_${number}_up'),
            tooltip: l10n.p11ParcelMoveUp,
            icon: const Icon(Icons.arrow_upward),
            onPressed: onMoveUp,
          ),
        if (onMoveDown != null)
          IconButton(
            key: ValueKey('parcel_stop_${number}_down'),
            tooltip: l10n.p11ParcelMoveDown,
            icon: const Icon(Icons.arrow_downward),
            onPressed: onMoveDown,
          ),
        if (onRemove != null)
          IconButton(
            key: ValueKey('parcel_stop_${number}_remove'),
            tooltip: l10n.p11ParcelRemoveStop,
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
      ],
    );
  }
}

/// Each drop-off of a multi-stop parcel: status, its own handover code
/// (while unused) and its own tracking link to share.
class ParcelStopsList extends StatelessWidget {
  final List<ParcelV2Stop> stops;
  final int? currentStop;

  const ParcelStopsList({super.key, required this.stops, this.currentStop});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.p11ParcelStopsTitle,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(l10n.p11ParcelStopCodesHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final stop in stops)
          Container(
            key: ValueKey('parcel_stop_row_${stop.sequence}'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: stop.sequence == currentStop
                    ? AppColors.primaryColor
                    : theme.colorScheme.outlineVariant,
                width: stop.sequence == currentStop ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.p11ParcelStopN(stop.sequence.toString()),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      parcelStopStatusLabel(l10n, stop.status),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: stop.status == ParcelStopStatus.failed
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (stop.address != null)
                  Text(
                    stop.address!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (stop.recipientName != null)
                  Text(
                    [stop.recipientName, stop.recipientPhone]
                        .whereType<String>()
                        .join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                if (stop.handoverCode != null && !stop.handoverVerified) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${l10n.p10ParcelHandoverCode}: ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        stop.handoverCode!,
                        key: ValueKey('parcel_stop_code_${stop.sequence}'),
                        style: const TextStyle(
                          fontSize: 18,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
                if (stop.trackingUrl != null && !stop.isDone)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      icon: const Icon(Icons.share, size: 18),
                      label: Text(l10n.p11ParcelShareStopLink),
                      onPressed: () => Share.share(
                        l10n.p10ParcelTrackingShareText(stop.trackingUrl!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Pay X cash to the courier at pickup" / "Paid at pickup".
class ParcelPayAtPickupNote extends StatelessWidget {
  final double amount;
  final String? currency;
  final bool collected;

  const ParcelPayAtPickupNote({
    super.key,
    required this.amount,
    required this.currency,
    this.collected = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orangeTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            collected ? Icons.check_circle : Icons.payments_outlined,
            color: Colors.black87,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              collected
                  ? l10n.p11ParcelPaidAtPickup
                  : l10n.p11ParcelPayAtPickupDue(
                      formatParcelMoney(amount, currency),
                    ),
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

/// Outstanding balance (e.g. a cash cancellation fee) shown before booking.
class ParcelDuesBanner extends StatelessWidget {
  final ParcelDuesSummary dues;

  const ParcelDuesBanner({super.key, required this.dues});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final text = dues.amounts.entries
        .where((e) => e.value > 0)
        .map((e) => formatParcelMoney(e.value, e.key))
        .join(' + ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.p11ParcelOutstandingBalance(text),
              style: TextStyle(color: colorScheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
