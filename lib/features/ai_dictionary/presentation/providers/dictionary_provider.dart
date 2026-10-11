// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/app_messenger.dart';
import '../../data/repositories/video_analysis_repository_impl.dart';
import '../../data/repositories/word_repository_impl.dart';
// با فرض استفاده از DTO
import '../../domain/entities/video_analysis.dart';
import '../../domain/entities/word_analysis.dart';

part 'dictionary_provider.g.dart';

// ==========================================
// Dictionary State Provider
// ==========================================
@riverpod
class Dictionary extends _$Dictionary {
  @override
  AsyncValue<WordAnalysis?> build() => const AsyncValue.data(null);

  Future<void> analyzeWord(String word) async {
    if (word.trim().isEmpty) return;
    state = const AsyncValue.loading();

    final result = await ref
        .read(wordRepositoryProvider)
        .fetchWordAnalysis(word);

    result.fold(
      onSuccess: (data) => state = AsyncValue.data(data),
      onFailure: (error) =>
          state = AsyncValue.error(error, error.stackTrace ?? StackTrace.empty),
    );
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

  /// متد جدید برای هندل کردن کلمات انتخاب شده از ترنسکریپت و چت
  Future<void> analyzeAndSaveFromSelection(String selectedText) async {
    final cleanText = selectedText.trim();
    if (cleanText.isEmpty) return;

    // نمایش اسنک‌بار لودینگ به کاربر
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('در حال آنالیز و افزودن به لایتنر...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // 1. آنالیز کلمه از طریق سرور AI (تولید مترادف‌های A1 تا C2)
      final analysisResult = await ref
          .read(wordRepositoryProvider)
          .fetchWordAnalysis(cleanText);

      if (analysisResult.isSuccess()) {
        // 2. ذخیره کلمه آنالیز شده در دیتابیس فلش‌کارت‌ها
        final wordData = analysisResult.getOrThrow();
        await saveWordToFlashcards(wordData, folder: 'General');

        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('لغت "$cleanText" با موفقیت آنالیز و اضافه شد!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Analysis failed');
      }
    } catch (e) {
      logger.error(
        'Failed to add selected word: $cleanText',
        error: e is Exception ? e : Exception(e),
      );
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('خطا در آنالیز لغت. لطفا دوباره تلاش کنید.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ==========================================
// Video Processing State Provider
// ==========================================
@riverpod
class VideoProcessing extends _$VideoProcessing {
  @override
  AsyncValue<VideoAnalysis?> build() => const AsyncValue.data(null);

  Future<void> analyzeYoutubeVideo(String url) async {
    if (url.trim().isEmpty) return;
    state = const AsyncValue.loading();

    final result = await ref
        .read(videoAnalysisRepositoryProvider)
        .processYoutubeVideo(url);

    result.fold(
      onSuccess: (data) => state = AsyncValue.data(data),
      onFailure: (error) =>
          state = AsyncValue.error(error, error.stackTrace ?? StackTrace.empty),
    );
  }

  Future<void> processAllPendingVideos() async {
    state = const AsyncValue.loading();

    final result = await ref
        .read(videoAnalysisRepositoryProvider)
        .processAllPendingVideos();

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (error) => state = AsyncValue.error(
        error.message,
        error.stackTrace ?? StackTrace.empty,
      ),
    );
  }

  void clear() => state = const AsyncValue.data(null);
}
