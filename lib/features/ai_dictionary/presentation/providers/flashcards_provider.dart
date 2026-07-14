import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/dictionary_repository.dart';

part 'flashcards_provider.g.dart';

@riverpod
class Flashcards extends _$Flashcards {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    return await ref
        .read(dictionaryRepositoryProvider)
        .getDueFlashcards(userId);
  }

  Future<void> reviewCard(
    int flashcardId,
    bool remembered,
    Map<String, dynamic> currentData,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    int repetition = currentData['repetition'] ?? 0;
    int interval = currentData['interval'] ?? 0;
    double easeFactor = (currentData['ease_factor'] ?? 2.5).toDouble();

    int quality = remembered ? 4 : 1;

    if (quality >= 3) {
      if (repetition == 0) {
        interval = 1;
      } else if (repetition == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetition++;
    } else {
      repetition = 0;
      interval = 1;
    }

    easeFactor =
        easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;

    final nextReview = DateTime.now()
        .add(Duration(days: interval))
        .toUtc()
        .toIso8601String();

    final updatedData = {
      'repetition': repetition,
      'interval': interval,
      'ease_factor': easeFactor,
      'next_review_date': nextReview,
    };

    if (state.hasValue) {
      final newList = List<Map<String, dynamic>>.from(state.value!);
      newList.removeWhere((item) => item['id'] == flashcardId);
      state = AsyncData(newList);
    }

    await ref
        .read(dictionaryRepositoryProvider)
        .updateFlashcardReview(
          userId: userId,
          flashcardId: flashcardId,
          quality: quality,
          updatedData: updatedData,
        );
  }
}
