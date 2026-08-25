import 'package:url_launcher/url_launcher.dart';

import 'package:hudhud_delivery/core/config/support_config.dart';

/// Opens the default mail client to contact support.
Future<bool> launchSupportEmail() {
  final uri = Uri(
    scheme: 'mailto',
    path: SupportConfig.supportEmail,
    queryParameters: {'subject': 'HudHud Delivery support'},
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Opens the phone dialer when [SupportConfig.supportPhoneE164] is set.
Future<bool> launchSupportPhone() {
  const n = SupportConfig.supportPhoneE164;
  if (n == null || n.isEmpty) {
    return Future.value(false);
  }
  final uri = Uri(scheme: 'tel', path: n);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
