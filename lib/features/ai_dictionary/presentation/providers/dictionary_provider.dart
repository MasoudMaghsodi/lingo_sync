import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/video_analysis_model.dart';
import '../../data/models/word_analysis_model.dart';
import '../../data/repositories/video_analysis_repository.dart';
import '../../data/repositories/word_repository.dart';

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
          .read(wordRepositoryProvider)
          .fetchWordAnalysis(word);
      state = AsyncValue.data(result.getOrThrow());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveWordToFlashcards(
    WordAnalysis wordData, {
    String folder = 'General',
  }) async {
    final result = await ref
        .read(wordRepositoryProvider)
        .saveToPersonalFlashcards(wordData, folder: folder);
    result.getOrThrow();
  }
}

// ==========================================
// پرووایدر پردازش ویدیو
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
          .read(videoAnalysisRepositoryProvider)
          .processYoutubeVideo(url);
      state = AsyncValue.data(result.getOrThrow());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> processAllPendingVideos() async {
    state = const AsyncValue.loading();
    try {
      // 🚀 ارتباط مستقیم با Supabase حذف شد و به گارسون محول شد
      final result = await ref
          .read(videoAnalysisRepositoryProvider)
          .processAllPendingVideos();

      result.when(
        success: (_) => state = const AsyncValue.data(null),
        failure: (error) => state = AsyncValue.error(
          error.message,
          error.stackTrace ?? StackTrace.empty,
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error('خطا در پردازش گروهی: $e', stack);
    }
  }

  void clear() => state = const AsyncValue.data(null);
}
