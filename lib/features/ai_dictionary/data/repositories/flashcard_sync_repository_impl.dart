import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/sync/outbox_sync_service.dart';
import '../../../../core/utils/uuid_generator.dart';
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
  final OutboxSyncService _outboxSync;

  // Hive Cache Boxes
  final Box _flashcardsBox = Hive.box(StorageConstants.hiveBoxFlashcards);

  // Protected system folders that cannot be renamed or deleted
  static const List<String> _protectedFolders = ['General', 'Grammar'];

  FlashcardSyncRepositoryImpl(this._supabase, [OutboxSyncService? outboxSync])
      : _outboxSync = outboxSync ?? OutboxSyncService();

  String _cacheKey(String userId) => 'due_$userId';

  @override
  List<FlashcardEntry> getCachedDueFlashcards(String userId) {
    final cachedData = _flashcardsBox.get(_cacheKey(userId));
    if (cachedData == null || cachedData is! List) return [];

    return cachedData.map(FlashcardEntryDto.fromRow).toList();
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
    // 1. Optimistic local cache update for instant UI feedback
    final cacheKey = _cacheKey(userId);
    final cachedData = _flashcardsBox.get(cacheKey);

    if (cachedData != null) {
      final list = List<dynamic>.from(cachedData);
      list.removeWhere((item) => item['id'] == flashcardId);
      await _flashcardsBox.put(cacheKey, list);
    }

    // 2. Queue into offline outbox with client-generated event UUID
    final clientEventId = UuidGenerator.v4();
    await _outboxSync.enqueue(
      explicitId: clientEventId,
      actionType: 'srs_review',
      payload: {
        'user_id': userId,
        'flashcard_id': flashcardId,
        'quality': quality,
        'repetition': updatedData['repetition'],
        'interval': updatedData['interval'],
        'ease_factor': updatedData['ease_factor'],
        'next_review_date': updatedData['next_review_date'],
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
        'device_id': 'flutter_mobile',
      },
    );

    // 3. Attempt immediate flush in background (idempotent, no-op if offline)
    unawaited(_outboxSync.flush(_supabase));
  }

  @override
  Future<bool> syncPendingActions() async {
    final result = await _outboxSync.flush(_supabase);
    return !result.hasNetworkError;
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

      final cards = (response as List).map(FlashcardEntryDto.fromRow).toList();

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
