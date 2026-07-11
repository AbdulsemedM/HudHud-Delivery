import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/core/widgets/section_header.dart';
import 'package:hudhud_delivery/features/sos/presentation/screens/emergency_contacts_screen.dart';
import 'package:hudhud_delivery/features/sos/presentation/screens/sos_history_screen.dart';
import 'package:hudhud_delivery/features/sos/presentation/widgets/sos_trigger_dialog.dart';

class SosSettingsScreen extends StatelessWidget {
  const SosSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.sosSettingsTitle),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.sp16),
        children: [
          SectionHeader(title: l10n.sosEmergencyContacts),
          _SosGroupCard(
            isDark: isDark,
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
              _SosTile(
                icon: Icons.history_rounded,
                iconColor: AppColors.infoColor,
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
            ],
          ),
          const SizedBox(height: AppColors.sp20),
          SectionHeader(title: l10n.sosTrigger),
          _SosGroupCard(
            isDark: isDark,
            borderColor: AppColors.errorColor.withOpacity(0.25),
            children: [
              _SosTile(
                icon: Icons.sos_rounded,
                iconColor: AppColors.errorColor,
                title: l10n.sosTrigger,
                subtitle: l10n.sosTriggerSubtitle,
                titleColor: AppColors.errorColor,
                onTap: () => showSosTriggerDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppColors.sp16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.sp4),
            child: Text(
              l10n.sosTriggerConfirmMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosGroupCard extends StatelessWidget {
  const _SosGroupCard({
    required this.children,
    required this.isDark,
    this.borderColor,
  });

  final List<Widget> children;
  final bool isDark;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.r16),
        side: BorderSide(
          color: borderColor ??
              (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 72,
                color: colorScheme.outlineVariant.withOpacity(0.35),
              ),
          ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppColors.sp16,
        vertical: AppColors.sp4,
      ),
      leading: IconBox(icon: icon, color: iconColor),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: titleColor ?? colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
        size: 22,
      ),
      onTap: onTap,
    );
  }
}
