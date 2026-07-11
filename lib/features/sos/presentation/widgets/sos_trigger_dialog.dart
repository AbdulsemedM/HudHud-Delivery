import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/features/sos/bloc/sos_bloc.dart';
import 'package:hudhud_delivery/features/sos/model/sos_trigger_request.dart';
import 'package:hudhud_delivery/features/sos/sos_bloc_provider.dart';

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
    final l10n = context.l10n;
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.r20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppColors.sp24,
            AppColors.sp24,
            AppColors.sp24,
            AppColors.sp16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBox(
                icon: Icons.sos_rounded,
                color: AppColors.errorColor,
              ),
              const SizedBox(height: AppColors.sp16),
              Text(
                l10n.sosTriggerConfirmTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppColors.sp12),
              Text(
                l10n.sosTriggerConfirmMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppColors.sp20),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.sosDescriptionHint,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkInputFill
                      : AppColors.lightInputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.r12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkInputBorder
                          : AppColors.lightInputBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.r12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkInputBorder
                          : AppColors.lightInputBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.r12),
                    borderSide: const BorderSide(
                      color: AppColors.errorColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppColors.sp20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSending ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.r12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(l10n.sosCancel),
                    ),
                  ),
                  const SizedBox(width: AppColors.sp12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.errorColor,
                            AppColors.errorDarkColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppColors.r12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppColors.r12),
                          onTap: _isSending ? null : _submit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      l10n.sosSendAlert,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
