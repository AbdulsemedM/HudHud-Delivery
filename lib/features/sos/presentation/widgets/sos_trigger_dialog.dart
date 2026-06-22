import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/features/sos/bloc/sos_bloc.dart';
import 'package:hudhud_delivery/features/sos/model/sos_trigger_request.dart';
import 'package:hudhud_delivery/features/sos/sos_bloc_provider.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

Future<bool> showSosTriggerDialog(
  BuildContext context, {
  int? orderId,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => sosBlocProvider(
      child: _SosTriggerDialog(orderId: orderId),
    ),
  );
  return result == true;
}

class _SosTriggerDialog extends StatefulWidget {
  final int? orderId;

  const _SosTriggerDialog({this.orderId});

  @override
  State<_SosTriggerDialog> createState() => _SosTriggerDialogState();
}

class _SosTriggerDialogState extends State<_SosTriggerDialog> {
  final _descriptionController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSending = true);
    final location = await StartupLocationService.fetchAtStartup();
    if (!mounted) return;
    if (location == null) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sosLocationRequired)),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    context.read<SosBloc>().add(
          TriggerSosEvent(
            SosTriggerRequest(
              orderId: widget.orderId,
              latitude: location.latitude,
              longitude: location.longitude,
              locationAddress: location.toString(),
              description: description.isEmpty
                  ? 'Emergency SOS alert'
                  : description,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocListener<SosBloc, SosState>(
      listener: (context, state) {
        if (state is SosError) {
          setState(() => _isSending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is SosLoaded && state.successMessage == 'sos_triggered') {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.lastTriggerResult?.message ?? l10n.sosTriggered,
              ),
            ),
          );
        }
      },
      child: AlertDialog(
        icon: Icon(Icons.sos, color: theme.colorScheme.error, size: 40),
        title: Text(l10n.sosTriggerConfirmTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.sosTriggerConfirmMessage),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.sosDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSending ? null : () => Navigator.pop(context, false),
            child: Text(l10n.sosCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: _isSending ? null : _submit,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.sosSendAlert),
          ),
        ],
      ),
    );
  }
}
