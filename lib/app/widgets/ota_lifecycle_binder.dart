import 'package:flutter/widgets.dart';

import 'package:hudhud_delivery/app/services/remote_config_service.dart';
import 'package:hudhud_delivery/app/services/shorebird_update_service.dart';

/// Runs silent Shorebird checks on first frame and when returning to foreground.
class OtaLifecycleBinder extends StatefulWidget {
  const OtaLifecycleBinder({super.key, required this.child});

  final Widget child;

  @override
  State<OtaLifecycleBinder> createState() => _OtaLifecycleBinderState();
}

class _OtaLifecycleBinderState extends State<OtaLifecycleBinder>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShorebirdUpdateService.instance.scheduleSilentCheck(reason: 'start');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh kill-switch / track flags, then check for patches.
      RemoteConfigService.instance.refresh().whenComplete(() {
        ShorebirdUpdateService.instance.scheduleSilentCheck(reason: 'resume');
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
