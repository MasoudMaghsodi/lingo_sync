import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/flashcard_entry.dart';
import '../../data/repositories/flashcard_sync_repository.dart';

part 'flashcards_provider.g.dart';

@riverpod
class Flashcards extends _$Flashcards {
  @override
  Future<List<FlashcardEntry>> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final repo = ref.watch(flashcardSyncRepositoryProvider);

    // Serve whatever is cached locally immediately — this is what makes
    // the deck usable offline / before the network round-trip completes.
    final cached = repo.getCachedDueFlashcards(userId);

    // Refresh from the server in the background. If it turns up different
    // data, invalidate so the next build re-reads the (now fresh) cache.
    unawaited(
      repo.refreshDueFlashcardsFromRemote(userId).then((changed) {
        if (changed && ref.mounted) {
          ref.invalidateSelf();
        }
      }),
    );

    // The repository (data layer) still deals in raw rows — this is the
    // one place that maps them into the domain type the rest of the app
    // sees.
    return cached.map(FlashcardEntry.fromRow).toList();
  }

  Future<void> reviewCard(FlashcardEntry card, bool remembered) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    int repetition = card.repetition;
    int interval = card.interval;
    double easeFactor = card.easeFactor;

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
      final newList = List<FlashcardEntry>.from(state.value!);
      newList.removeWhere((item) => item.id == card.id);
      state = AsyncData(newList);
    }

    await ref
        .read(flashcardSyncRepositoryProvider)
        .updateFlashcardReview(
          userId: userId,
          flashcardId: card.id,
          quality: quality,
          updatedData: updatedData,
        );
  }
}
