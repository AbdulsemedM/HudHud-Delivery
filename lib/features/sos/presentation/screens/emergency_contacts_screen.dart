import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/features/sos/bloc/sos_bloc.dart';
import 'package:hudhud_delivery/features/sos/model/emergency_contact_model.dart';
import 'package:hudhud_delivery/features/sos/presentation/screens/emergency_contact_form_screen.dart';
import 'package:hudhud_delivery/features/sos/sos_bloc_provider.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return sosBlocProvider(
      child: const _EmergencyContactsBody(),
    );
  }
}

class _EmergencyContactsBody extends StatefulWidget {
  const _EmergencyContactsBody();

  @override
  State<_EmergencyContactsBody> createState() => _EmergencyContactsBodyState();
}

class _EmergencyContactsBodyState extends State<_EmergencyContactsBody> {
  @override
  void initState() {
    super.initState();
    context.read<SosBloc>().add(const LoadLocalContactsEvent());
  }

  Future<void> _openForm({EmergencyContactModel? contact}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<SosBloc>(),
          child: EmergencyContactFormScreen(contact: contact),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(EmergencyContactModel contact) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AuthModal.confirm(
      context: context,
      title: l10n.sosDeleteContact,
      message: l10n.sosDeleteContactConfirm,
      confirmLabel: l10n.sosDeleteContact,
      cancelLabel: l10n.sosCancel,
      destructive: true,
    );
    if (confirmed == true && mounted) {
      context.read<SosBloc>().add(DeleteEmergencyContactEvent(contact.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileDarkPage(
      title: l10n.sosEmergencyContacts,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AuthScreenColors.orange,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l10n.sosAddContact),
      ),
      body: BlocConsumer<SosBloc, SosState>(
        listener: (context, state) {
          if (state is SosError) {
            AuthSnackBar.error(context, state.message);
          }
          if (state is SosLoaded && state.successMessage != null) {
            final msg = switch (state.successMessage) {
              'contact_added' => l10n.sosContactAdded,
              'contact_updated' => l10n.sosContactUpdated,
              'contact_deleted' => l10n.sosContactDeleted,
              _ => state.successMessage!,
            };
            AuthSnackBar.success(context, msg);
          }
        },
        builder: (context, state) {
          if (state is SosLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final contacts =
              state is SosLoaded ? state.contacts : <EmergencyContactModel>[];
          if (contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.contact_emergency_outlined,
                      size: 56,
                      color: AuthScreenColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.sosNoContacts,
                      style: const TextStyle(
                        color: AuthScreenColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.sosNoContactsSubtitle,
                      style: const TextStyle(
                        color: AuthScreenColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Material(
                color: AuthScreenColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AuthScreenColors.surfaceBorder),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AuthScreenColors.orange.withValues(alpha: 0.2),
                    foregroundColor: AuthScreenColors.orange,
                    child: Text(
                      contact.name.isNotEmpty
                          ? contact.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(
                    contact.name,
                    style: const TextStyle(color: AuthScreenColors.textPrimary),
                  ),
                  subtitle: Text(
                    [
                      contact.phone,
                      if (contact.relationship != null &&
                          contact.relationship!.isNotEmpty)
                        contact.relationship,
                      if (contact.isPrimary) 'Primary',
                    ].whereType<String>().join(' · '),
                    style: const TextStyle(color: AuthScreenColors.textSecondary),
                  ),
                  trailing: PopupMenuButton<String>(
                    color: AuthScreenColors.surface,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openForm(contact: contact);
                      } else if (value == 'delete') {
                        _confirmDelete(contact);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.sosEditContact),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l10n.sosDeleteContact,
                          style: const TextStyle(color: Color(0xFFEF5350)),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _openForm(contact: contact),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
