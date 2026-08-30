import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hudhud_delivery/core/config/support_config.dart';

/// Opens the default mail client to contact support.
Future<bool> launchSupportEmail() {
  final uri = Uri(
    scheme: 'mailto',
    path: SupportConfig.supportEmail,
    queryParameters: {'subject': 'HudHud Delivery support'},
  );
  return launchUrl(uri, mode: LaunchMode.platformDefault);
}

/// Opens the phone dialer when a support phone is configured.
///
/// On iOS, uses [LaunchMode.platformDefault] (not externalApplication) so the
/// Phone app can handle `tel:` / `telprompt:` short codes. Simulator has no
/// Phone app and will always fail with NSOSStatusErrorDomain -10814.
Future<bool> launchSupportPhone() async {
  final n = SupportConfig.supportPhoneE164.trim();
  if (n.isEmpty) return false;

  // Prefer Uri.parse so short codes stay as tel:9491 (not oddly encoded).
  final candidates = <Uri>[
    if (!kIsWeb && Platform.isIOS) Uri.parse('telprompt:$n'),
    Uri.parse('tel:$n'),
  ];

  for (final uri in candidates) {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (launched) return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('launchSupportPhone failed for $uri: $e');
      }
    }
  }
  return false;
}
