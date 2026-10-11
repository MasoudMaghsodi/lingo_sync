import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../domain/entities/word_analysis.dart';
import '../../domain/repositories/i_word_repository.dart';
import '../models/word_analysis_dto.dart';
import '../services/ai_server_client.dart';

part 'word_repository_impl.g.dart';

@riverpod
IWordRepository wordRepository(Ref ref) {
  return WordRepositoryImpl(
    Supabase.instance.client,
    ref.watch(aiServerClientProvider),
  );
}

class WordRepositoryImpl implements IWordRepository {
  final SupabaseClient _supabase;
  final AiServerClient _aiClient;

  // Cache Stampede prevention map
  final Map<String, Future<Result<WordAnalysis>>> _inflightRequests = {};

  WordRepositoryImpl(this._supabase, this._aiClient);

  @override
  Future<Result<WordAnalysis>> fetchWordAnalysis(String word) async {
    final cleanWord = word.trim().toLowerCase();

    if (_inflightRequests.containsKey(cleanWord)) {
      logger.debug(
        'Returning in-flight request for: $cleanWord',
        context: 'WordRepositoryImpl',
      );
      return _inflightRequests[cleanWord]!;
    }

    final requestFuture = _executeWordFetch(cleanWord);
    _inflightRequests[cleanWord] = requestFuture;

    try {
      return await requestFuture;
    } finally {
      await _inflightRequests.remove(cleanWord);
    }
  }

  Future<Result<WordAnalysis>> _executeWordFetch(String cleanWord) async {
    try {
      // 1. Check Global Dictionary Cache
      final cachedData = await _supabase
          .from('global_dictionary')
          .select()
          .eq('word', cleanWord)
          .maybeSingle();

      if (cachedData != null) {
        return Result<WordAnalysis>.success(
          WordAnalysisDto.fromJson(cachedData['ai_analysis']),
        );
      }

      // 2. Fetch from Node.js AI Express Server
      final response = await errorHandler.executeWithRetry(
        operation: () => _aiClient.postJson('/analyze_word', {
          'word': cleanWord,
        }, timeout: const Duration(seconds: 30)),
        context: 'WordRepositoryImpl.fetchWordAnalysis',
      );

      final aiResult = WordAnalysisDto.fromJson(jsonDecode(response.body));

      // 3. Upsert to Global Dictionary
      await _supabase.from('global_dictionary').upsert({
        'word': cleanWord,
        'ai_analysis': WordAnalysisDto.toJson(aiResult),
      }, onConflict: 'word');

      return Result<WordAnalysis>.success(aiResult);
    } catch (e, st) {
      return Result<WordAnalysis>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'WordRepositoryImpl.fetchWordAnalysis',
        ),
      );
    }
  }

  @override
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
      // Ensure word exists in global dictionary before linking
      final globalRes = await _supabase
          .from('global_dictionary')
          .upsert({
            'word': wordData.word.toLowerCase(),
            'ai_analysis': WordAnalysisDto.toJson(wordData),
          }, onConflict: 'word')
          .select('id')
          .single();

      // Insert into user's personal flashcards
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
          context: 'WordRepositoryImpl.saveToPersonalFlashcards',
        ),
      );
    }
  }

  @override
  Future<Result<void>> addCustomWordManually(
    WordAnalysis customWord, {
    String folder = 'General',
  }) async {
    // Reusing the same saving logic since WordAnalysis is cleanly decoupled
    return saveToPersonalFlashcards(customWord, folder: folder);
  }
}
