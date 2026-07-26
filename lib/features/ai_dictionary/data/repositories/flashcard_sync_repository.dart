import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/result/result.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';
import 'package:lingo_sync/features/ai_dictionary/data/models/flashcard_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/logging/app_logger.dart';

part 'flashcard_sync_repository.g.dart';

@riverpod
FlashcardSyncRepository flashcardSyncRepository(Ref ref) {
  return FlashcardSyncRepository(Supabase.instance.client);
}

class FlashcardSyncRepository {
  final SupabaseClient _supabase;

  // استفاده از فایل Constants که در فاز ۱ ساختیم
  final Box _flashcardsBox = Hive.box(StorageConstants.hiveBoxFlashcards);
  final Box _pendingSyncBox = Hive.box(
    StorageConstants.hiveBoxCache,
  ); // آپدیت شد به نام باکس استاندارد

  FlashcardSyncRepository(this._supabase);

  String _cacheKey(String userId) => 'due_$userId';

  List<Map<String, dynamic>> getCachedDueFlashcards(String userId) {
    final cachedData = _flashcardsBox.get(_cacheKey(userId));
    if (cachedData == null) return [];
    return List<Map<String, dynamic>>.from(
      (cachedData as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<bool> refreshDueFlashcardsFromRemote(String userId) async {
    // اگر سینک‌های قبلی شکست بخورد، ریکوئست‌های جدید را اسپم نمی‌کنیم
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
      // ذخیره در صف آفلاین
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
        context: 'FlashcardSync',
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

  /// خروجی این تابع حالا bool است. اگر به دلیل قطعی نت متوقف شود، false برمی‌گرداند.
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
          context: 'FlashcardSync',
        );
        return false; // خروج سریع (Fail-Fast) به جای لوپ شدن روی تمام آیتم‌های صف
      }
    }
    return true;
  }

  // ==========================================
  // متدهای جدید اضافه‌شده برای پاکسازی لایه UI
  // ==========================================

  /// دریافت تمامی فلش‌کارت‌های کاربر (برای صفحه آرشیو)
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
      final cards = rows.map(FlashcardEntry.fromRow).toList();
      return Result.success(cards);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'FlashcardSyncRepository.getAllFlashcards',
        ),
      );
    }
  }

  /// تغییر نام یک پوشه
  Future<Result<void>> renameFolder(String oldName, String newName) async {
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
          context: 'FlashcardSyncRepository.renameFolder',
        ),
      );
    }
  }

  /// حذف یک پوشه (انتقال کارت‌های آن به General)
  Future<Result<void>> deleteFolder(String folderName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure(const AuthException('Not authenticated'));
    }

    try {
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
          context: 'FlashcardSyncRepository.deleteFolder',
        ),
      );
    }
  }

  /// انتقال یک فلش‌کارت خاص به یک پوشه دیگر
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
          context: 'FlashcardSyncRepository.moveFlashcard',
        ),
      );
    }
  }
}
