import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/features/sos/presentation/screens/emergency_contacts_screen.dart';
import 'package:hudhud_delivery/features/sos/presentation/screens/sos_history_screen.dart';
import 'package:hudhud_delivery/features/sos/presentation/widgets/sos_trigger_dialog.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class SosSettingsScreen extends StatelessWidget {
  const SosSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileDarkPage(
      title: l10n.sosSettingsTitle,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SosTile(
            icon: Icons.contact_emergency_outlined,
            iconColor: AuthScreenColors.orange,
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
            iconColor: AuthScreenColors.orange,
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
            iconColor: const Color(0xFFEF5350),
            title: l10n.sosTrigger,
            subtitle: l10n.sosTriggerSubtitle,
            titleColor: const Color(0xFFEF5350),
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
    return Material(
      color: AuthScreenColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AuthScreenColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: iconColor.withValues(alpha: 0.12),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: titleColor ?? AuthScreenColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AuthScreenColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AuthScreenColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
