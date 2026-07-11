import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Shows a slim banner when the device has no network interface (radio off / offline).
class AppConnectivityBanner extends StatefulWidget {
  final Widget child;

  const AppConnectivityBanner({super.key, required this.child});

  @override
  State<AppConnectivityBanner> createState() => _AppConnectivityBannerState();
}

class _AppConnectivityBannerState extends State<AppConnectivityBanner> {
  List<ConnectivityResult> _connectivity = [ConnectivityResult.none];
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  static bool _isOffline(List<ConnectivityResult> r) {
    if (r.isEmpty) return true;
    return r.length == 1 && r[0] == ConnectivityResult.none;
  }

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((r) => setState(() => _connectivity = r));
    Connectivity()
        .checkConnectivity()
        .then((r) {
          if (mounted) {
            setState(() => _connectivity = r);
          }
        })
        .catchError((_) {
          if (mounted) {
            setState(() => _connectivity = [ConnectivityResult.none]);
          }
        });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline(_connectivity)) {
      return widget.child;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Material(
          color: colorScheme.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                l10n.offlineNoConnection,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
