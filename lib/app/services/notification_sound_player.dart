import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Plays the HudHud notification clip when a push is received.
class NotificationSoundPlayer {
  NotificationSoundPlayer._();

  static const assetPath = 'assets/sound/notification_sound.mpeg';

  static AudioPlayer? _player;

  static Future<void> play() async {
    final previous = _player;
    _player = null;
    if (previous != null) {
      try {
        await previous.stop();
        await previous.dispose();
      } catch (_) {}
    }

    final player = AudioPlayer();
    _player = player;
    try {
      await _configureNotificationSession();
      await player.setVolume(1.0);
      if (!kIsWeb && Platform.isAndroid) {
        // Same stream as system / other-app notification sounds
        // (not media/music volume, which is often much lower).
        await player.setAndroidAudioAttributes(
          const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.sonification,
            usage: AndroidAudioUsage.notification,
          ),
        );
      }

      final duration = await player.setAsset(assetPath);
      final waitFor = duration == null || duration == Duration.zero
          ? const Duration(milliseconds: 800)
          : duration;
      await player.play();
      await Future<void>.delayed(waitFor);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationSoundPlayer: $e');
      }
    } finally {
      if (identical(_player, player)) {
        _player = null;
        await player.dispose();
      }
    }
  }

  static Future<void> _configureNotificationSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.sonification,
            usage: AndroidAudioUsage.notification,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
          androidWillPauseWhenDucked: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationSoundPlayer session: $e');
      }
    }
  }
}
