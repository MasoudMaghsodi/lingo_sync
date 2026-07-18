import 'dart:convert';

import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/result/result.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

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

/// Owns single-word dictionary lookups and personal-flashcard creation
/// from a [WordAnalysis]. Split out of the old God-object
/// `DictionaryRepository`, which also handled video analysis and the
/// offline flashcard-review cache — none of which belongs here.
///
/// [saveToPersonalFlashcards] is also how grammar points get saved — see
/// `VideoLessonPage._saveGrammarToAnki`, which builds a [WordAnalysis] from
/// a `GrammarPoint` and calls this with `folder: 'Grammar'`. Routing both
/// through this single method (instead of grammar points doing their own
/// raw insert) is what keeps every flashcard row in one consistent shape —
/// `word_id` pointing at `global_dictionary` — rather than the two
/// divergent shapes the app used to write.
class WordRepository {
  final SupabaseClient _supabase;
  final AiServerClient _aiClient;

  WordRepository(this._supabase, this._aiClient);

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
        operation: () => _aiClient.postJson('/analyze_word', {
          'word': cleanWord,
        }, timeout: const Duration(seconds: 30)),
        context: 'WordRepository.fetchWordAnalysis',
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
          context: 'WordRepository.fetchWordAnalysis',
        ),
      );
    }
  }

  /// Saves [wordData] as a personal flashcard for the current user, under
  /// [folder] (defaults to 'General').
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
          context: 'WordRepository.saveToPersonalFlashcards',
        ),
      );
    }
  }
}
