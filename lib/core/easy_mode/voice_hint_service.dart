import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around [FlutterTts] for Easy Mode spoken hints.
class VoiceHintService {
  VoiceHintService._();
  static final VoiceHintService instance = VoiceHintService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  String? _locale;

  /// True while speech is actually playing.
  ///
  /// Exists so the Listen button can become a Stop button. Without it there
  /// was no way to silence a hint once it started: the service could stop,
  /// but nothing in the UI could ask it to, so a customer who tapped Listen
  /// by accident — or in a quiet room — had to wait the sentence out.
  final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);

  Future<void> init({String? languageCode}) async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      if (languageCode != null) {
        await setLanguage(languageCode);
      }
      // Every end state clears the flag. A handler that fires only on the
      // happy path leaves the button stuck showing Stop with nothing to stop.
      _tts.setCompletionHandler(() => speaking.value = false);
      _tts.setCancelHandler(() => speaking.value = false);
      _tts.setErrorHandler((_) => speaking.value = false);
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
      speaking.value = true;
      await _tts.speak(trimmed);
    } catch (e) {
      speaking.value = false;
      if (kDebugMode) debugPrint('VoiceHintService speak failed: $e');
    }
  }

  /// Speak, or silence it if this same hint is already playing.
  ///
  /// What the Listen button calls. Tapping it twice mutes rather than
  /// restarting the sentence from the top.
  Future<void> toggle(String text) async {
    if (speaking.value) {
      await stop();
      return;
    }
    await speak(text);
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    // Set regardless: on some platforms stop() does not fire the cancel
    // handler, and a button stuck on Stop is worse than one that stops early.
    speaking.value = false;
  }

  void dispose() {
    _tts.stop();
    speaking.value = false;
  }
}
