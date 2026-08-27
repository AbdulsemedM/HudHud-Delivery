import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around [FlutterTts] for Easy Mode spoken hints.
class VoiceHintService {
  VoiceHintService._();
  static final VoiceHintService instance = VoiceHintService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  String? _locale;

  Future<void> init({String? languageCode}) async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      if (languageCode != null) {
        await setLanguage(languageCode);
      }
      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('VoiceHintService init failed: $e');
      _ready = false;
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _locale = languageCode;
    final mapped = switch (languageCode) {
      'am' => 'am-ET',
      'om' => 'om-ET',
      'so' => 'so-SO',
      'ar' => 'ar-SA',
      _ => 'en-US',
    };
    try {
      await _tts.setLanguage(mapped);
    } catch (_) {
      try {
        await _tts.setLanguage('en-US');
      } catch (_) {}
    }
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!_ready) await init(languageCode: _locale);
    try {
      await _tts.stop();
      await _tts.speak(trimmed);
    } catch (e) {
      if (kDebugMode) debugPrint('VoiceHintService speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _tts.stop();
  }
}
