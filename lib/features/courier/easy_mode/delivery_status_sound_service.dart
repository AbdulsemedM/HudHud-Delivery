import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

/// Plays short status chimes during delivery tracking.
class DeliveryStatusSoundService {
  DeliveryStatusSoundService._();
  static final DeliveryStatusSoundService instance =
      DeliveryStatusSoundService._();

  final AudioPlayer _player = AudioPlayer();
  String? _lastPlayedKey;

  Future<void> playStatusChange(String statusKey) async {
    if (statusKey.isEmpty || statusKey == _lastPlayedKey) return;
    _lastPlayedKey = statusKey;
    try {
      await _player.stop();
      await _player.setAsset('assets/sound/notification_sound.mpeg');
      await _player.play();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DeliveryStatusSoundService failed: $e');
      }
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
