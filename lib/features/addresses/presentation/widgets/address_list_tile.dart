import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 4),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppColors.primaryColor
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
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
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.addressesDefaultBadge,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.displayText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_typeLabel(context)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode)
                PopupMenuButton<String>(
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
