import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';

part 'tts_service.g.dart';

@Riverpod(keepAlive: true)
TtsService ttsService(Ref ref) {
  final service = TtsService();

  // وقتی پرووایدر از بین برود (مثلا هنگام خروج از اکانت)، موتور صوتی هم خاموش می‌شود
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45);
      // رفع باگ روی هم افتادن صداها در فلاتر:
      await _flutterTts.awaitSpeakCompletion(true);
      _isInitialized = true;
    } catch (e) {
      logger.error(
        'Failed to initialize TTS engine',
        error: e as Exception,
        context: 'TtsService',
      );
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInitialized();
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      logger.error(
        'Failed to speak text',
        error: e as Exception,
        context: 'TtsService',
      );
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void setCompletionHandler(void Function() callback) {
    _flutterTts.setCompletionHandler(callback);
  }

  void clearCompletionHandler() {
    _flutterTts.setCompletionHandler(() {});
  }

  /// متد جدید برای آزادسازی کامل حافظه
  void dispose() {
    _flutterTts.stop();
    clearCompletionHandler();
    logger.info('TTS Engine disposed safely', context: 'TtsService');
  }
}
