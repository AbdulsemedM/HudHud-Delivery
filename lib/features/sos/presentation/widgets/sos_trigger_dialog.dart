import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
import 'package:hudhud_delivery/features/sos/bloc/sos_bloc.dart';
import 'package:hudhud_delivery/features/sos/model/sos_trigger_request.dart';
import 'package:hudhud_delivery/features/sos/sos_bloc_provider.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

Future<bool> showSosTriggerDialog(
  BuildContext context, {
  int? orderId,
}) async {
  final result = await AuthModal.dialog<bool>(
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
      AuthSnackBar.error(context, l10n.sosLocationRequired);
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

    return BlocListener<SosBloc, SosState>(
      listener: (context, state) {
        if (state is SosError) {
          setState(() => _isSending = false);
          AuthSnackBar.error(context, state.message);
        }
        if (state is SosLoaded && state.successMessage == 'sos_triggered') {
          Navigator.of(context).pop(true);
          AuthSnackBar.success(
            context,
            state.lastTriggerResult?.message ?? l10n.sosTriggered,
          );
        }
      },
      child: AuthAlertDialog(
        title: l10n.sosTriggerConfirmTitle,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.sos,
                color: Color(0xFFEF5350),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(l10n.sosTriggerConfirmMessage),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.sosDescriptionHint,
                ),
              ),
            ],
          ),
        ),
        actions: [
          AuthDialogAction(
            label: l10n.sosCancel,
            enabled: !_isSending,
            onPressed: () => Navigator.pop(context, false),
          ),
          AuthDialogAction(
            label: l10n.sosSendAlert,
            filled: true,
            destructive: true,
            enabled: !_isSending,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
