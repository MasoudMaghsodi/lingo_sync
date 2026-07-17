import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tts_service.g.dart';

// keepAlive: true — text-to-speech is used from many independent pages
// (dictionary, flashcards, grammar vault, video lessons). Each of those
// used to create its own FlutterTts() instance with its own
// setLanguage/setSpeechRate init call on every page visit, which is
// wasteful and meant several independent native TTS engine instances
// could exist at once. One shared, app-lifetime instance is simpler and
// correct.
@Riverpod(keepAlive: true)
TtsService ttsService(Ref ref) => TtsService();

/// Thin wrapper around [FlutterTts] with one-time initialization, shared
/// across the whole app via [ttsServiceProvider].
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInitialized();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Registers [callback] to run when the current utterance finishes.
  /// Only one handler can be active at a time across the whole app — a
  /// page that relies on this (e.g. to toggle a "stop speaking" icon)
  /// must call [clearCompletionHandler] in its own `dispose()`, so a
  /// disposed page's callback never fires after it's gone and never
  /// silently overrides a handler another page still needs.
  void setCompletionHandler(void Function() callback) {
    _flutterTts.setCompletionHandler(callback);
  }

  void clearCompletionHandler() {
    _flutterTts.setCompletionHandler(() {});
  }
}
