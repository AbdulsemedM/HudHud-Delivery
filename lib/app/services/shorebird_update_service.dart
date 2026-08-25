import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'package:hudhud_delivery/app/services/ota_log.dart';
import 'package:hudhud_delivery/app/services/remote_config_service.dart';

/// Silent Shorebird patch check + background download.
///
/// Patches are NOT force-applied mid-session. After download, Shorebird applies
/// them on the next natural process restart.
///
/// Store binaries: `shorebird release android|ios`
/// Dart OTA patches: `shorebird patch android|ios` (optional `--track`)
class ShorebirdUpdateService {
  ShorebirdUpdateService({
    ShorebirdUpdater? updater,
    RemoteConfigService? remoteConfig,
    this.timeout = const Duration(seconds: 15),
    this.minIntervalBetweenChecks = const Duration(minutes: 5),
  })  : _updater = updater ?? ShorebirdUpdater(),
        _remoteConfig = remoteConfig ?? RemoteConfigService.instance;

  static final ShorebirdUpdateService instance = ShorebirdUpdateService();

  final ShorebirdUpdater _updater;
  final RemoteConfigService _remoteConfig;
  final Duration timeout;
  final Duration minIntervalBetweenChecks;

  bool _inFlight = false;
  DateTime? _lastCheckAt;

  /// Fire-and-forget safe entry point for app start / resume.
  void scheduleSilentCheck({String reason = 'manual'}) {
    // Do not await — never block UI / navigation.
    checkAndDownloadSilently(reason: reason);
  }

  /// Checks for a patch and downloads it in the background when allowed.
  Future<void> checkAndDownloadSilently({String reason = 'manual'}) async {
    if (kDebugMode) {
      OtaLog.info('patch_skip', {'reason': 'debug_mode', 'trigger': reason});
      return;
    }
    if (!_updater.isAvailable) {
      OtaLog.info('patch_skip', {
        'reason': 'updater_unavailable',
        'trigger': reason,
      });
      return;
    }
    if (_remoteConfig.isPatchKillSwitchEnabled) {
      OtaLog.warn('patch_skip', {
        'reason': 'kill_switch_patch_disabled',
        'trigger': reason,
      });
      return;
    }
    if (_inFlight) {
      OtaLog.info('patch_skip', {'reason': 'in_flight', 'trigger': reason});
      return;
    }
    final last = _lastCheckAt;
    if (last != null &&
        DateTime.now().difference(last) < minIntervalBetweenChecks &&
        reason == 'resume') {
      OtaLog.info('patch_skip', {
        'reason': 'throttled',
        'trigger': reason,
      });
      return;
    }

    _inFlight = true;
    try {
      await _runCheck(reason: reason).timeout(
        timeout,
        onTimeout: () {
          OtaLog.warn('patch_check_timeout', {'trigger': reason});
        },
      );
    } catch (e, st) {
      OtaLog.error(
        'patch_check_failed',
        error: e,
        stackTrace: st,
        data: {'trigger': reason},
      );
    } finally {
      _inFlight = false;
      _lastCheckAt = DateTime.now();
    }
  }

  Future<void> _runCheck({required String reason}) async {
    final trackName = _remoteConfig.shorebirdUpdateTrack;
    final track = trackName == 'stable'
        ? UpdateTrack.stable
        : UpdateTrack(trackName);

    OtaLog.info('patch_check_start', {
      'trigger': reason,
      'track': trackName,
    });

    final status = await _updater.checkForUpdate(track: track);
    OtaLog.info('patch_check_status', {
      'trigger': reason,
      'status': status.name,
      'track': trackName,
    });

    switch (status) {
      case UpdateStatus.outdated:
        OtaLog.info('patch_download_start', {
          'trigger': reason,
          'track': trackName,
        });
        await _updater.update(track: track);
        OtaLog.info('patch_download_complete', {
          'trigger': reason,
          'track': trackName,
          'applies_on': 'next_natural_restart',
        });
        break;
      case UpdateStatus.restartRequired:
        // Already downloaded; wait for natural restart — do not force.
        OtaLog.info('patch_restart_pending', {
          'trigger': reason,
          'note': 'waiting_for_natural_restart',
        });
        break;
      case UpdateStatus.upToDate:
      case UpdateStatus.unavailable:
        break;
    }
  }
}
