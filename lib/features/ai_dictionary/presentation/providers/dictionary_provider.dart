import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/word_analysis_model.dart';
import '../../data/models/video_analysis_model.dart';
import '../../data/repositories/dictionary_repository.dart';

part 'dictionary_provider.g.dart';

// ==========================================
// پرووایدر دیکشنری تک لغت
// ==========================================
@riverpod
class Dictionary extends _$Dictionary {
  @override
  AsyncValue<WordAnalysis?> build() => const AsyncValue.data(null);

  Future<void> analyzeWord(String word) async {
    if (word.trim().isEmpty) return;
    state = const AsyncValue.loading();
    try {
      final result = await ref
          .read(dictionaryRepositoryProvider)
          .fetchWordAnalysis(word);
      state = AsyncValue.data(result.getOrThrow());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveWordToFlashcards(WordAnalysis wordData) async {
    final result = await ref
        .read(dictionaryRepositoryProvider)
        .saveToPersonalFlashcards(wordData);
    result.getOrThrow();
  }
}

// ==========================================
// پرووایدر ویدیو (تغییر نام برای جلوگیری از تداخل با مدل VideoAnalysis)
// بازگشت متد حیاتی processAllPendingVideos
// ==========================================
@riverpod
class VideoProcessing extends _$VideoProcessing {
  @override
  AsyncValue<VideoAnalysis?> build() => const AsyncValue.data(null);

  Future<void> analyzeYoutubeVideo(String url) async {
    if (url.trim().isEmpty) return;
    state = const AsyncValue.loading();
    try {
      final result = await ref
          .read(dictionaryRepositoryProvider)
          .processYoutubeVideo(url);
      state = AsyncValue.data(result.getOrThrow());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> processAllPendingVideos() async {
    state = const AsyncValue.loading();
    try {
      final supabase = Supabase.instance.client;
      final pendingTasks = await supabase
          .from('daily_tasks')
          .select()
          .not('video_url', 'is', null)
          .eq('is_ai_processed', false);

      if (pendingTasks.isEmpty) {
        state = const AsyncValue.error(
          'تمام ویدیوها پردازش شده‌اند.',
          StackTrace.empty,
        );
        return;
      }

      for (var task in pendingTasks) {
        final videoUrl = task['video_url'] as String;
        final taskId = task['id'] as int;

        try {
          final result = await ref
              .read(dictionaryRepositoryProvider)
              .processYoutubeVideo(videoUrl);
          result.getOrThrow();
          await supabase
              .from('daily_tasks')
              .update({'is_ai_processed': true})
              .eq('id', taskId);
        } catch (e) {
          debugPrint('Skipped task $taskId: $e');
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error('خطا در پردازش گروهی: $e', stack);
    }
  }

  void clear() => state = const AsyncValue.data(null);
}
