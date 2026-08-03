import 'package:package_info_plus/package_info_plus.dart';

import 'package:hudhud_delivery/app/services/ota_log.dart';
import 'package:hudhud_delivery/app/services/remote_config_service.dart';
import 'package:hudhud_delivery/core/utils/version_compare.dart';

class ForceUpdateCheckResult {
  const ForceUpdateCheckResult({
    required this.required,
    required this.currentVersion,
    required this.minimumSupportedVersion,
    required this.latestStoreVersion,
  });

  final bool required;
  final String currentVersion;
  final String minimumSupportedVersion;
  final String latestStoreVersion;
}

/// Compares the running app version to Remote Config min/latest store versions.
class ForceUpdateService {
  ForceUpdateService({RemoteConfigService? remoteConfig})
      : _remoteConfig = remoteConfig ?? RemoteConfigService.instance;

  final RemoteConfigService _remoteConfig;

  Future<ForceUpdateCheckResult> check() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    final minimum = _remoteConfig.minimumSupportedVersion;
    final latest = _remoteConfig.latestStoreVersionForPlatform;
    final required = compareVersionStrings(current, minimum) < 0;

    OtaLog.info('force_update_check', {
      'current': current,
      'minimum': minimum,
      'latest_android': _remoteConfig.latestStoreVersionAndroid,
      'latest_ios': _remoteConfig.latestStoreVersionIos,
      'latest_platform': latest,
      'required': required,
    });

    return ForceUpdateCheckResult(
      required: required,
      currentVersion: current,
      minimumSupportedVersion: minimum,
      latestStoreVersion: latest,
    );
  }
}
