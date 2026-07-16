import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lingo_sync/core/config/app_config.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/result/result.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';
import '../models/word_analysis_model.dart';
import '../models/video_analysis_model.dart';

part 'dictionary_repository.g.dart';

@riverpod
DictionaryRepository dictionaryRepository(Ref ref) {
  return DictionaryRepository(Supabase.instance.client);
}

class DictionaryRepository {
  final SupabaseClient _supabase;
  final Box _flashcardsBox = Hive.box('flashcards_cache');
  final Box _pendingSyncBox = Hive.box('pending_sync');

  DictionaryRepository(this._supabase);

  /// Base URL for the AI Express backend, read from .env via [AppConfig].
  String get _aiServerUrl => AppConfig.aiServerBaseUrl;

  /// Extracts an 11-character YouTube video id from a URL, or null if the
  /// URL doesn't match / the captured group is missing. Never force-unwraps
  /// a possibly-null regex group.
  String? _extractYoutubeVideoId(String url) {
    final regExp = RegExp(
      r"^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*",
    );
    final match = regExp.firstMatch(url);
    final group7 = match?.group(7);
    if (group7 != null && group7.length == 11) return group7;
    return null;
  }

  /// Reads an `{"error": "..."}` shaped body defensively — AI server error
  /// responses are always JSON, but proxies/timeouts can return HTML or an
  /// empty body, and this must never crash on `jsonDecode` in that case.
  String _extractServerErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {
      // Body wasn't valid JSON — fall through to a generic message.
    }
    return 'AI server returned an unreadable error response.';
  }

  /// Wraps a raw HTTP call so connectivity failures (timeouts, DNS, socket
  /// errors) surface as a retryable [NetworkException] — this is what lets
  /// [ErrorHandlerService.executeWithRetry] decide whether to retry.
  /// Non-2xx responses are treated as [ApiException] (a business error from
  /// the AI server, e.g. an invalid word) and are deliberately NOT
  /// retryable.
  Future<http.Response> _postJson(
    String endpoint,
    Map<String, dynamic> body, {
    required Duration timeout,
  }) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_aiServerUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw NetworkException(
        'Request to $endpoint timed out',
        isRetryable: true,
      );
    } catch (e) {
      throw NetworkException(
        'Failed to reach AI server at $endpoint: $e',
        isRetryable: true,
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(
        _extractServerErrorMessage(response.body),
        endpoint: endpoint,
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  // ==========================================
  // جستجوی لغت (تغییر یافته به سرور اختصاصی Node.js)
  // ==========================================
  Future<Result<WordAnalysis>> fetchWordAnalysis(String word) async {
    try {
      final cleanWord = word.trim().toLowerCase();

      // 1. چک کردن کش دیتابیس گلوبال
      final cachedData = await _supabase
          .from('global_dictionary')
          .select()
          .eq('word', cleanWord)
          .maybeSingle();
      if (cachedData != null) {
        return Result<WordAnalysis>.success(
          WordAnalysis.fromJson(cachedData['ai_analysis']),
        );
      }

      // 2. درخواست به سرور اختصاصی Node.js (با تلاش مجدد خودکار روی خطای شبکه)
      final response = await errorHandler.executeWithRetry(
        operation: () => _postJson('/analyze_word', {
          'word': cleanWord,
        }, timeout: const Duration(seconds: 30)),
        context: 'DictionaryRepository.fetchWordAnalysis',
      );

      final aiResult = WordAnalysis.fromJson(jsonDecode(response.body));

      await _supabase.from('global_dictionary').upsert({
        'word': cleanWord,
        'ai_analysis': aiResult.toJson(),
      });
      return Result<WordAnalysis>.success(aiResult);
    } catch (e, st) {
      return Result<WordAnalysis>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'DictionaryRepository.fetchWordAnalysis',
        ),
      );
    }
  }

  // ==========================================
  // پردازش ویدیو (تغییر یافته به سرور اختصاصی Node.js)
  // ==========================================
  Future<Result<VideoAnalysis>> processYoutubeVideo(String url) async {
    try {
      final videoId = _extractYoutubeVideoId(url);

      if (videoId != null) {
        final cachedData = await _supabase
            .from('video_analysis')
            .select()
            .eq('video_id', videoId)
            .maybeSingle();
        if (cachedData != null) {
          return Result<VideoAnalysis>.success(
            VideoAnalysis.fromJson(cachedData),
          );
        }
      }

      final response = await errorHandler.executeWithRetry(
        operation: () => _postJson('/process_youtube', {
          'videoUrl': url,
        }, timeout: const Duration(seconds: 60)),
        context: 'DictionaryRepository.processYoutubeVideo',
      );

      final videoAnalysis = VideoAnalysis.fromJson(jsonDecode(response.body));

      // ذخیره در دیتابیس برای نفر بعدی
      await _supabase.from('video_analysis').upsert({
        'video_id': videoAnalysis.videoId,
        'summary': videoAnalysis.summary,
        'full_transcript_translation': videoAnalysis.fullTranscriptTranslation,
        'grammar_points': videoAnalysis.grammarPoints
            .map(
              (e) => {
                'structure_name': e.structureName,
                'persian_explanation': e.persianExplanation,
                'example_from_transcript': e.exampleFromTranscript,
              },
            )
            .toList(),
        'vocabulary': videoAnalysis.vocabulary.map((e) => e.toJson()).toList(),
      });

      return Result<VideoAnalysis>.success(videoAnalysis);
    } catch (e, st) {
      return Result<VideoAnalysis>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'DictionaryRepository.processYoutubeVideo',
        ),
      );
    }
  }

  // ==========================================
  // متدهای قدرتمند جعبه لایتنر شما
  // ==========================================
  Future<Result<void>> saveToPersonalFlashcards(
    WordAnalysis wordData, {
    String folder = 'General',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Result<void>.failure(
        const AuthException('No authenticated user', code: 'not_authenticated'),
      );
    }

    try {
      final globalRes = await _supabase
          .from('global_dictionary')
          .upsert({
            'word': wordData.word.toLowerCase(),
            'ai_analysis': wordData.toJson(),
          }, onConflict: 'word')
          .select('id')
          .single();

      await _supabase.from('flashcards').insert({
        'user_id': user.id, 'word_id': globalRes['id'],
        'folder_name': folder, // پوشه‌بندی برای لغات و گرامر
        'repetition': 0, 'interval': 0, 'ease_factor': 2.5,
        'next_review_date': DateTime.now().toUtc().toIso8601String(),
      });
      return Result<void>.success(null);
    } catch (e, st) {
      return Result<void>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'DictionaryRepository.saveToPersonalFlashcards',
        ),
      );
    }
  }

  // Unchanged for now — the local-cache-first + fire-and-forget remote sync
  // design here (and its known "stale until reopened" race condition) is
  // addressed together with the flashcard schema split in a later
  // refactor phase, not as part of this error-handling unification.
  Future<List<Map<String, dynamic>>> getDueFlashcards(String userId) async {
    final cacheKey = 'due_$userId';
    final cachedData = _flashcardsBox.get(cacheKey);
    List<Map<String, dynamic>> localFlashcards = [];

    if (cachedData != null) {
      localFlashcards = List<Map<String, dynamic>>.from(
        (cachedData as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }

    _syncDueFlashcardsFromRemote(userId, cacheKey);
    syncPendingActions();
    return localFlashcards;
  }

  Future<void> _syncDueFlashcardsFromRemote(
    String userId,
    String cacheKey,
  ) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await _supabase
          .from('flashcards')
          .select('*, global_dictionary(*)')
          .eq('user_id', userId)
          .lte('next_review_date', now)
          .order('next_review_date', ascending: true);
      await _flashcardsBox.put(cacheKey, response);
    } catch (_) {}
  }

  Future<void> updateFlashcardReview({
    required String userId,
    required int flashcardId,
    required int quality,
    required Map<String, dynamic> updatedData,
  }) async {
    final cacheKey = 'due_$userId';
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
