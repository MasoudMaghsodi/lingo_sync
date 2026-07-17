import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flashcard_sync_repository.g.dart';

@riverpod
FlashcardSyncRepository flashcardSyncRepository(Ref ref) {
  return FlashcardSyncRepository(Supabase.instance.client);
}

/// Owns the due-flashcards local cache (Hive), the offline pending-sync
/// queue, and the SM-2-driven review update. Split out of the old
/// God-object `DictionaryRepository` because none of this has anything to
/// do with word lookups or video analysis — it's purely "keep today's
/// review deck usable offline and eventually consistent with the server".
class FlashcardSyncRepository {
  final SupabaseClient _supabase;
  final Box _flashcardsBox = Hive.box('flashcards_cache');
  final Box _pendingSyncBox = Hive.box('pending_sync');

  FlashcardSyncRepository(this._supabase);

  String _cacheKey(String userId) => 'due_$userId';

  /// Returns whatever is currently cached locally for [userId], with no
  /// network call — safe to call even fully offline.
  List<Map<String, dynamic>> getCachedDueFlashcards(String userId) {
    final cachedData = _flashcardsBox.get(_cacheKey(userId));
    if (cachedData == null) return [];
    return List<Map<String, dynamic>>.from(
      (cachedData as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  /// Fetches the current due-flashcards list from Supabase and overwrites
  /// the local cache with it. Flushes any queued offline review updates
  /// first, so a review made while offline is never overwritten by a
  /// stale remote read.
  ///
  /// Returns true if the refreshed data differs from what was cached
  /// before this call, so callers (e.g. `FlashcardsProvider`) know whether
  /// it's worth invalidating and rebuilding — this is what fixes the old
  /// "stale until you manually reopen the page" bug: the sync used to
  /// silently update the Hive cache with no way for the UI to know it
  /// should re-read it.
  Future<bool> refreshDueFlashcardsFromRemote(String userId) async {
    await syncPendingActions();

    final before = _flashcardsBox.get(_cacheKey(userId));
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await _supabase
          .from('flashcards')
          .select('*, global_dictionary(*)')
          .eq('user_id', userId)
          .lte('next_review_date', now)
          .order('next_review_date', ascending: true);
      await _flashcardsBox.put(_cacheKey(userId), response);
      return before?.toString() != response.toString();
    } catch (_) {
      // Network unavailable or request failed — keep serving the existing
      // cache rather than surfacing an error for a background refresh.
      return false;
    }
  }

  Future<void> updateFlashcardReview({
    required String userId,
    required int flashcardId,
    required int quality,
    required Map<String, dynamic> updatedData,
  }) async {
    final cacheKey = _cacheKey(userId);
    final cachedData = _flashcardsBox.get(cacheKey);
    if (cachedData != null) {
      final list = List<dynamic>.from(cachedData);
      list.removeWhere((item) => item['id'] == flashcardId);
      await _flashcardsBox.put(cacheKey, list);
    }
    try {
      await _updateRemote(userId, flashcardId, quality, updatedData);
    } catch (e) {
      await _pendingSyncBox.add({
        'type': 'update_review',
        'user_id': userId,
        'flashcard_id': flashcardId,
        'quality': quality,
        'data': updatedData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _updateRemote(
    String userId,
    int flashcardId,
    int quality,
    Map<String, dynamic> data,
  ) async {
    await _supabase
        .from('flashcards')
        .update({
          'repetition': data['repetition'],
          'interval': data['interval'],
          'ease_factor': data['ease_factor'],
          'next_review_date': data['next_review_date'],
        })
        .eq('id', flashcardId);
    await _supabase.from('review_logs').insert({
      'user_id': userId,
      'flashcard_id': flashcardId,
      'quality': quality,
    });
  }

  Future<void> syncPendingActions() async {
    if (_pendingSyncBox.isEmpty) return;
    for (var key in _pendingSyncBox.keys.toList()) {
      final action = _pendingSyncBox.get(key);
      try {
        if (action['type'] == 'update_review') {
          await _updateRemote(
            action['user_id'],
            action['flashcard_id'],
            action['quality'],
            Map<String, dynamic>.from(action['data']),
          );
        }
        await _pendingSyncBox.delete(key);
      } catch (e) {
        break;
      }
    }
  }
}
