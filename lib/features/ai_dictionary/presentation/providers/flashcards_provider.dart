import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/flashcard_sync_repository.dart';

part 'flashcards_provider.g.dart';

@riverpod
class Flashcards extends _$Flashcards {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final repo = ref.watch(flashcardSyncRepositoryProvider);

    // Serve whatever is cached locally immediately — this is what makes
    // the deck usable offline / before the network round-trip completes.
    final cached = repo.getCachedDueFlashcards(userId);

    // Refresh from the server in the background. If it turns up different
    // data, invalidate so the next build re-reads the (now fresh) cache.
    // Previously this sync ran silently with no way for the UI to know it
    // should re-read the cache, leaving the deck stale until the page was
    // manually reopened.
    unawaited(
      repo.refreshDueFlashcardsFromRemote(userId).then((changed) {
        if (changed && ref.mounted) {
          ref.invalidateSelf();
        }
      }),
    );

    return cached;
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

    final int quality = remembered ? 4 : 1;

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
        .read(flashcardSyncRepositoryProvider)
        .updateFlashcardReview(
          userId: userId,
          flashcardId: flashcardId,
          quality: quality,
          updatedData: updatedData,
        );
  }
}
