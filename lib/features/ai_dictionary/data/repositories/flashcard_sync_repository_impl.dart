import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../domain/entities/flashcard_entry.dart';
import '../../domain/repositories/i_flashcard_sync_repository.dart';
import '../models/flashcard_entry_dto.dart';

part 'flashcard_sync_repository_impl.g.dart';

@riverpod
IFlashcardSyncRepository flashcardSyncRepository(Ref ref) {
  return FlashcardSyncRepositoryImpl(Supabase.instance.client);
}

class FlashcardSyncRepositoryImpl implements IFlashcardSyncRepository {
  final SupabaseClient _supabase;

  // Hive Cache Boxes
  final Box _flashcardsBox = Hive.box(StorageConstants.hiveBoxFlashcards);
  final Box _pendingSyncBox = Hive.box(StorageConstants.hiveBoxCache);

  // Protected system folders that cannot be renamed or deleted
  static const List<String> _protectedFolders = ['General', 'Grammar'];

  FlashcardSyncRepositoryImpl(this._supabase);

  String _cacheKey(String userId) => 'due_$userId';

  @override
  List<FlashcardEntry> getCachedDueFlashcards(String userId) {
    final cachedData = _flashcardsBox.get(_cacheKey(userId));
    if (cachedData == null) return [];

    final rawList = List<Map<String, dynamic>>.from(
      (cachedData as List).map((e) => Map<String, dynamic>.from(e)),
    );

    return rawList.map(FlashcardEntryDto.fromRow).toList();
  }

  @override
  Future<bool> refreshDueFlashcardsFromRemote(String userId) async {
    final syncSuccess = await syncPendingActions();
    if (!syncSuccess) return false;

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
      return false;
    }
  }

  @override
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
      // Offline mode: queue for sync
      await _pendingSyncBox.add({
        'type': 'update_review',
        'user_id': userId,
        'flashcard_id': flashcardId,
        'quality': quality,
        'data': updatedData,
        'timestamp': DateTime.now().toIso8601String(),
      });
      logger.warning(
        'Offline mode: Review queued for sync',
        context: 'FlashcardSyncImpl',
      );
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

  @override
  Future<bool> syncPendingActions() async {
    if (_pendingSyncBox.isEmpty) return true;

    for (final key in _pendingSyncBox.keys.toList()) {
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
        logger.warning(
          'Sync interrupted due to network failure',
          context: 'FlashcardSyncImpl',
        );
        return false;
      }
    }
    return true;
  }

  @override
  Future<Result<List<FlashcardEntry>>> getAllFlashcards() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure(
        const AuthException('Not authenticated', code: 'not_authenticated'),
      );
    }

    try {
      final response = await _supabase
          .from('flashcards')
          .select('*, global_dictionary(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(response);
      final cards = rows.map(FlashcardEntryDto.fromRow).toList();

      return Result.success(cards);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'FlashcardSyncImpl.getAllFlashcards',
        ),
      );
    }
  }

  @override
  Future<Result<void>> renameFolder(String oldName, String newName) async {
    if (_protectedFolders.contains(oldName)) {
      return Result.failure(
        const ValidationException('Cannot rename system folders.'),
      );
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure(const AuthException('Not authenticated'));
    }

    try {
      await _supabase
          .from('flashcards')
          .update({'folder_name': newName})
          .eq('folder_name', oldName)
          .eq('user_id', userId);

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'FlashcardSyncImpl.renameFolder',
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteFolder(String folderName) async {
    if (_protectedFolders.contains(folderName)) {
      return Result.failure(
        const ValidationException('Cannot delete system folders.'),
      );
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure(const AuthException('Not authenticated'));
    }

    try {
      // Moves flashcards back to General instead of deleting them
      await _supabase
          .from('flashcards')
          .update({'folder_name': 'General'})
          .eq('folder_name', folderName)
          .eq('user_id', userId);

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'FlashcardSyncImpl.deleteFolder',
        ),
      );
    }
  }

  @override
  Future<Result<void>> moveFlashcard(int flashcardId, String newFolder) async {
    try {
      await _supabase
          .from('flashcards')
          .update({'folder_name': newFolder})
          .eq('id', flashcardId);
      return Result.success(null);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'FlashcardSyncImpl.moveFlashcard',
        ),
      );
    }
  }
}
