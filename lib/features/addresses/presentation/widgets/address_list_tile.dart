import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/features/addresses/model/address_model.dart';

class AddressListTile extends StatelessWidget {
  final AddressModel address;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSetDefault;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AddressListTile({
    super.key,
    required this.address,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onSetDefault,
    this.onEdit,
    this.onDelete,
  });

  String _typeLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (address.addressType) {
      case 'home':
        return l10n.addressesTypeHome;
      case 'work':
        return l10n.addressesTypeWork;
      default:
        return l10n.addressesTypeOther;
    }
  }

  IconData _typeIcon() {
    switch (address.addressType) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline_rounded;
      default:
        return Icons.location_on_outlined;
    }
  }

  Color _typeColor() {
    switch (address.addressType) {
      case 'home':
        return AppColors.primaryColor;
      case 'work':
        return AppColors.secondaryColor;
      default:
        return AppColors.infoColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.r16),
        side: BorderSide(
          color: address.isDefault
              ? AppColors.primaryColor.withValues(alpha: 0.35)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppColors.r16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 8),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppColors.primaryColor
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              IconBox(icon: _typeIcon(), color: _typeColor()),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppColors.rFull),
                            ),
                            child: Text(
                              l10n.addressesDefaultBadge,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      address.displayText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor().withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppColors.rFull),
                      ),
                      child: Text(
                        _typeLabel(context),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _typeColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.r12),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'default':
                        onSetDefault?.call();
                        break;
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!address.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Text(l10n.addressesSetDefault),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(l10n.addressesEdit),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.actionDelete),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
