import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'package:hudhud_delivery/app/services/ota_log.dart';
import 'package:hudhud_delivery/core/config/store_config.dart';

/// Opens the Play Store / App Store listing for this app.
Future<bool> openAppStoreListing() async {
  final uri = storeListingUri();
  OtaLog.info('open_store_listing', {'uri': uri.toString()});
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    OtaLog.warn('open_store_listing_failed', {'uri': uri.toString()});
  }
  return launched;
}

Uri storeListingUri() {
  if (Platform.isAndroid) {
    return Uri.parse(
      'https://play.google.com/store/apps/details?id=${StoreConfig.androidPackageId}',
    );
  }
  if (StoreConfig.iosAppStoreId.isNotEmpty) {
    return Uri.parse(
      'https://apps.apple.com/app/id${StoreConfig.iosAppStoreId}',
    );
  }
  return Uri.parse(
    'https://apps.apple.com/search?term=${Uri.encodeComponent(StoreConfig.appDisplayName)}',
  );
}
