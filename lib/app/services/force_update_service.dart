import 'package:package_info_plus/package_info_plus.dart';

import 'package:hudhud_delivery/app/services/ota_log.dart';
import 'package:hudhud_delivery/app/services/remote_config_service.dart';
import 'package:hudhud_delivery/core/utils/version_compare.dart';

enum UpdateGate {
  /// Installed version meets the store latest (or latest is unset/equal).
  none,

  /// Above the hard minimum, but below the published store version.
  soft,

  /// Below the platform minimum — must update from the store.
  force,
}

class ForceUpdateCheckResult {
  const ForceUpdateCheckResult({
    required this.gate,
    required this.currentVersion,
    required this.minimumSupportedVersion,
    required this.latestStoreVersion,
  });

  final UpdateGate gate;
  final String currentVersion;
  final String minimumSupportedVersion;
  final String latestStoreVersion;

  bool get required => gate == UpdateGate.force;
  bool get softSuggested => gate == UpdateGate.soft;
}

/// Compares [current] to [minimum] / [latest] without I/O (testable).
UpdateGate decideUpdateGate({
  required String current,
  required String minimum,
  required String latest,
}) {
  if (compareVersionStrings(current, minimum) < 0) {
    return UpdateGate.force;
  }
  // Soft prompt only when latest is a real newer release.
  if (latest.trim().isNotEmpty &&
      compareVersionStrings(current, latest) < 0) {
    return UpdateGate.soft;
  }
  return UpdateGate.none;
}

/// Compares the running app version to Remote Config min/latest store versions.
class ForceUpdateService {
  ForceUpdateService({RemoteConfigService? remoteConfig})
      : _remoteConfig = remoteConfig ?? RemoteConfigService.instance;

  final RemoteConfigService _remoteConfig;

  Future<ForceUpdateCheckResult> check() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    final minimum = _remoteConfig.minimumSupportedVersionForPlatform;
    final latest = _remoteConfig.latestStoreVersionForPlatform;
    final gate = decideUpdateGate(
      current: current,
      minimum: minimum,
      latest: latest,
    );

    OtaLog.info('force_update_check', {
      'current': current,
      'minimum': minimum,
      'minimum_android': _remoteConfig.minimumSupportedVersionAndroid,
      'minimum_ios': _remoteConfig.minimumSupportedVersionIos,
      'minimum_legacy': _remoteConfig.minimumSupportedVersion,
      'latest_android': _remoteConfig.latestStoreVersionAndroid,
      'latest_ios': _remoteConfig.latestStoreVersionIos,
      'latest_platform': latest,
      'gate': gate.name,
    });

    return ForceUpdateCheckResult(
      gate: gate,
      currentVersion: current,
      minimumSupportedVersion: minimum,
      latestStoreVersion: latest,
    );
  }
}
