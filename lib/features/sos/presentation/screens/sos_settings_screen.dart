import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/sos/presentation/screens/emergency_contacts_screen.dart';
import 'package:hudhud_delivery/features/sos/presentation/screens/sos_history_screen.dart';
import 'package:hudhud_delivery/features/sos/presentation/widgets/sos_trigger_dialog.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class SosSettingsScreen extends StatelessWidget {
  const SosSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sosSettingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SosTile(
            icon: Icons.contact_emergency_outlined,
            iconColor: AppColors.primaryColor,
            title: l10n.sosEmergencyContacts,
            subtitle: l10n.sosEmergencyContactsSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmergencyContactsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _SosTile(
            icon: Icons.history,
            iconColor: AppColors.primaryColor,
            title: l10n.sosHistory,
            subtitle: l10n.sosHistorySubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SosHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _SosTile(
            icon: Icons.sos,
            iconColor: colorScheme.error,
            title: l10n.sosTrigger,
            subtitle: l10n.sosTriggerSubtitle,
            titleColor: colorScheme.error,
            onTap: () => showSosTriggerDialog(context),
          ),
        ],
      ),
    );
  }
}

class _SosTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  const _SosTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: titleColor ?? colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
