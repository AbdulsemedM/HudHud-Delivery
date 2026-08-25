import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/sos/presentation/widgets/sos_trigger_dialog.dart';

class SosTriggerButton extends StatelessWidget {
  final int? orderId;
  final bool compact;

  const SosTriggerButton({
    super.key,
    this.orderId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'SOS',
        onPressed: () => showSosTriggerDialog(context, orderId: orderId),
        icon: Icon(
          Icons.sos,
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      onPressed: () => showSosTriggerDialog(context, orderId: orderId),
      icon: const Icon(Icons.sos),
      label: const Text('SOS'),
    );
  }
}
