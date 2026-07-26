import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/error_handler_service.dart';
import '../models/word_analysis_model.dart';
import '../services/ai_server_client.dart';

part 'word_repository.g.dart';

@riverpod
WordRepository wordRepository(Ref ref) {
  return WordRepository(
    Supabase.instance.client,
    ref.watch(aiServerClientProvider),
  );
}

class WordRepository {
  final SupabaseClient _supabase;
  final AiServerClient _aiClient;

  // قفل حافظه برای جلوگیری از Cache Stampede (درخواست‌های تکراری همزمان)
  final Map<String, Future<Result<WordAnalysis>>> _inflightRequests = {};

  WordRepository(this._supabase, this._aiClient);

  Future<Result<WordAnalysis>> fetchWordAnalysis(String word) async {
    final cleanWord = word.trim().toLowerCase();

    // اگر همین الان درخواستی برای این کلمه در حال پردازش است، همان را برگردان
    if (_inflightRequests.containsKey(cleanWord)) {
      logger.debug(
        'Returning in-flight request for: $cleanWord',
        context: 'WordRepository',
      );
      return _inflightRequests[cleanWord]!;
    }

    // ایجاد یک فیوچر جدید و ذخیره در مپ قفل
    final requestFuture = _executeWordFetch(cleanWord);
    _inflightRequests[cleanWord] = requestFuture;

    try {
      return await requestFuture;
    } finally {
      // چه موفق شد و چه شکست خورد، قفل را باز کن
      await _inflightRequests.remove(cleanWord);
    }
  }

  Future<Result<WordAnalysis>> _executeWordFetch(String cleanWord) async {
    try {
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

      // 2. درخواست به سرور اختصاصی Node.js
      final response = await errorHandler.executeWithRetry(
        operation: () => _aiClient.postJson('/analyze_word', {
          'word': cleanWord,
        }, timeout: const Duration(seconds: 30)),
        context: 'WordRepository.fetchWordAnalysis',
      );

      final aiResult = WordAnalysis.fromJson(jsonDecode(response.body));

      await _supabase.from('global_dictionary').upsert({
        'word': cleanWord,
        'ai_analysis': aiResult.toJson(),
      }, onConflict: 'word');

      return Result<WordAnalysis>.success(aiResult);
    } catch (e, st) {
      return Result<WordAnalysis>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'WordRepository.fetchWordAnalysis',
        ),
      );
    }
  }

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
        'user_id': user.id,
        'word_id': globalRes['id'],
        'folder_name': folder,
        'repetition': 0,
        'interval': 0,
        'ease_factor': 2.5,
        'next_review_date': DateTime.now().toUtc().toIso8601String(),
      });
      return Result<void>.success(null);
    } catch (e, st) {
      return Result<void>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'WordRepository.saveToPersonalFlashcards',
        ),
      );
    }
  }
}
