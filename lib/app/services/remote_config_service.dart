import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'ota_log.dart';

/// Firebase Remote Config for store force-update + Shorebird kill switch.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  static const String keyMinimumSupportedVersion = 'minimum_supported_version';
  static const String keyLatestStoreVersionAndroid =
      'latest_store_version_android';
  static const String keyLatestStoreVersionIos = 'latest_store_version_ios';
  static const String keyKillSwitchPatchDisabled = 'kill_switch_patch_disabled';
  static const String keyShorebirdUpdateTrack = 'shorebird_update_track';

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Defaults keep the app usable until console values are set.
  static final Map<String, dynamic> _defaults = {
    keyMinimumSupportedVersion: '0.0.0',
    keyLatestStoreVersionAndroid: '1.0.0',
    keyLatestStoreVersionIos: '1.0.0',
    keyKillSwitchPatchDisabled: false,
    keyShorebirdUpdateTrack: 'stable',
  };

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        OtaLog.warn('remote_config_skip', {'reason': 'firebase_not_initialized'});
        return;
      }
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));
      await remoteConfig.setDefaults(_defaults);
      await remoteConfig.fetchAndActivate();
      _remoteConfig = remoteConfig;
      _initialized = true;
      OtaLog.info('remote_config_ready', {
        'minimum_supported_version': minimumSupportedVersion,
        'latest_store_version_android': latestStoreVersionAndroid,
        'latest_store_version_ios': latestStoreVersionIos,
        'kill_switch_patch_disabled': isPatchKillSwitchEnabled,
        'shorebird_update_track': shorebirdUpdateTrack,
      });
    } catch (e, st) {
      OtaLog.error(
        'remote_config_init_failed',
        error: e,
        stackTrace: st,
      );
      // Fail open: defaults via getters when uninitialized.
    }
  }

  Future<void> refresh() async {
    if (!_initialized || _remoteConfig == null) {
      await initialize();
      return;
    }
    try {
      await _remoteConfig!.fetchAndActivate();
      OtaLog.info('remote_config_refreshed');
    } catch (e, st) {
      OtaLog.error('remote_config_refresh_failed', error: e, stackTrace: st);
    }
  }

  String get minimumSupportedVersion =>
      _remoteConfig?.getString(keyMinimumSupportedVersion) ??
      _defaults[keyMinimumSupportedVersion] as String;

  String get latestStoreVersionAndroid =>
      _remoteConfig?.getString(keyLatestStoreVersionAndroid) ??
      _defaults[keyLatestStoreVersionAndroid] as String;

  String get latestStoreVersionIos =>
      _remoteConfig?.getString(keyLatestStoreVersionIos) ??
      _defaults[keyLatestStoreVersionIos] as String;

  /// Latest store version for the current platform (Android or iOS).
  String get latestStoreVersionForPlatform {
    if (Platform.isIOS) return latestStoreVersionIos;
    return latestStoreVersionAndroid;
  }

  bool get isPatchKillSwitchEnabled =>
      _remoteConfig?.getBool(keyKillSwitchPatchDisabled) ??
      _defaults[keyKillSwitchPatchDisabled] as bool;

  /// Shorebird track name (`stable`, `staging`, `beta`, …).
  String get shorebirdUpdateTrack {
    final track = (_remoteConfig?.getString(keyShorebirdUpdateTrack) ??
            _defaults[keyShorebirdUpdateTrack] as String)
        .trim();
    return track.isEmpty ? 'stable' : track;
  }
}
