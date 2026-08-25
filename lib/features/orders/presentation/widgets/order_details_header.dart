import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/system_ui_style.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/orders/data/models/order_model.dart';
import 'package:hudhud_delivery/features/sos/presentation/widgets/sos_trigger_button.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

/// Collapsing hero + toolbar for [OrderDetailsScreen].
class OrderDetailsSliverHeader extends StatelessWidget {
  const OrderDetailsSliverHeader({
    super.key,
    required this.order,
    required this.onChat,
    this.onCancel,
  });

  final OrderModel order;
  final VoidCallback onChat;
  final VoidCallback? onCancel;

  static String compactOrderNumber(String orderNumber) {
    final trimmed = orderNumber.trim();
    if (trimmed.length <= 18) return trimmed;
    return '${trimmed.substring(0, 10)}…${trimmed.substring(trimmed.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final collapsedTitle = compactOrderNumber(order.orderNumber);

    return SliverAppBar(
      expandedHeight: 228 + topPadding,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: systemUiOverlayFor(context),
      leadingWidth: 52,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: _HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        collapsedTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      centerTitle: false,
      actions: [
        SosTriggerButton(compact: true, orderId: order.id),
        _OrderHeaderMenu(order: order, onCancel: onCancel),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: _OrderDetailsHeroBackground(
          order: order,
          topPadding: topPadding,
          onChat: onChat,
        ),
      ),
    );
  }
}

class _OrderDetailsHeroBackground extends StatelessWidget {
  const _OrderDetailsHeroBackground({
    required this.order,
    required this.topPadding,
    required this.onChat,
  });

  final OrderModel order;
  final double topPadding;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final statusColor = order.statusColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                Color.lerp(AppColors.primaryColor, AppColors.primaryDarkColor, 0.55)!,
                AppColors.primaryDarkColor,
              ],
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightOnPrimary.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -24,
          left: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightOnPrimary.withValues(alpha: 0.06),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 150;
            final showChips = constraints.maxHeight >= 168;

            return Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 56, 20, 14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: compact ? 44 : 52,
                          height: compact ? 44 : 52,
                          decoration: BoxDecoration(
                            color: AppColors.lightOnPrimary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.lightOnPrimary.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.lightOnPrimary,
                            size: compact ? 24 : 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.orderAppBarTitle('').split('#').first.trim(),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.lightOnPrimary.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.orderNumber,
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: (compact
                                        ? theme.textTheme.titleMedium
                                        : theme.textTheme.titleLarge)
                                    ?.copyWith(
                                  color: AppColors.lightOnPrimary,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (!compact) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _StatusPill(
                                      label: order.statusDisplayName,
                                      color: statusColor,
                                    ),
                                    Text(
                                      order.formattedTotal,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: AppColors.lightOnPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showChips)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _HeaderActionChip(
                              icon: Icons.chat_bubble_rounded,
                              label: AppLocalizations.of(context)!.chatOrderTitle,
                              filled: true,
                              onTap: onChat,
                            ),
                            const SizedBox(width: 8),
                            _HeaderActionChip(
                              icon: Icons.copy_rounded,
                              label: 'Copy ID',
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: '${order.id}'),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.orderIdCopied)),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _HeaderActionChip(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              onTap: () {
                                Share.share(
                                  'Order #${order.orderNumber} (ID: ${order.id})\n${order.status}',
                                  subject: l10n.orderShareSubject,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.lightTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionChip extends StatelessWidget {
  const _HeaderActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? AppColors.lightSurface
        : AppColors.lightOnPrimary.withValues(alpha: 0.16);
    final fg = filled ? AppColors.primaryColor : AppColors.lightOnPrimary;
    final border = filled
        ? null
        : Border.all(color: AppColors.lightOnPrimary.withValues(alpha: 0.35));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.semiTransparent.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: AppColors.lightOnPrimary),
        ),
      ),
    );
  }
}

class _OrderHeaderMenu extends StatelessWidget {
  const _OrderHeaderMenu({
    required this.order,
    this.onCancel,
  });

  final OrderModel order;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.semiTransparent.withValues(alpha: 0.22),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert_rounded, color: AppColors.lightOnPrimary, size: 22),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        switch (value) {
          case 'copy':
            await Clipboard.setData(ClipboardData(text: '${order.id}'));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.orderIdCopied)),
              );
            }
          case 'share':
            Share.share(
              'Order #${order.orderNumber} (ID: ${order.id})\n${order.status}',
              subject: l10n.orderShareSubject,
            );
          case 'cancel':
            onCancel?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'copy',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.copy_rounded, size: 22),
            title: Text(l10n.copyOrderId),
            subtitle: Text('#${order.id}', style: const TextStyle(fontSize: 12)),
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.share_rounded, size: 22),
            title: Text(l10n.shareOrder),
          ),
        ),
        if (onCancel != null)
          PopupMenuItem(
            value: 'cancel',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.cancel_outlined, size: 22, color: scheme.error),
              title: Text(
                l10n.cancelOrder,
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
