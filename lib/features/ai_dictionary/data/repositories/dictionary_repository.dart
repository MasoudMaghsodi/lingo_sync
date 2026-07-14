import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

  // 🚀 آی‌پی سرور هوش مصنوعی جدیدت را اینجا وارد کن
  final String _aiServerUrl = 'http://194.246.82.160:3002/api';

  DictionaryRepository(this._supabase);

  // ==========================================
  // جستجوی لغت (تغییر یافته به سرور اختصاصی Node.js)
  // ==========================================
  Future<WordAnalysis> fetchWordAnalysis(String word) async {
    final cleanWord = word.trim().toLowerCase();

    // 1. چک کردن کش دیتابیس گلوبال
    final cachedData = await _supabase
        .from('global_dictionary')
        .select()
        .eq('word', cleanWord)
        .maybeSingle();
    if (cachedData != null) {
      return WordAnalysis.fromJson(cachedData['ai_analysis']);
    }

    // 2. درخواست به سرور اختصاصی Node.js
    final response = await http
        .post(
          Uri.parse('$_aiServerUrl/analyze_word'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'word': cleanWord}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error']);
    }

    final aiResult = WordAnalysis.fromJson(jsonDecode(response.body));

    await _supabase.from('global_dictionary').upsert({
      'word': cleanWord,
      'ai_analysis': aiResult.toJson(),
    });
    return aiResult;
  }

  // ==========================================
  // پردازش ویدیو (تغییر یافته به سرور اختصاصی Node.js)
  // ==========================================
  Future<VideoAnalysis> processYoutubeVideo(String url) async {
    final regExp = RegExp(
      r"^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*",
    );
    final match = regExp.firstMatch(url);
    final videoId = (match != null && match.group(7)!.length == 11)
        ? match.group(7)!
        : null;

    if (videoId != null) {
      final cachedData = await _supabase
          .from('video_analysis')
          .select()
          .eq('video_id', videoId)
          .maybeSingle();
      if (cachedData != null) return VideoAnalysis.fromJson(cachedData);
    }

    final response = await http
        .post(
          Uri.parse('$_aiServerUrl/process_youtube'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'videoUrl': url}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error']);
    }

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

    return videoAnalysis;
  }

  // ==========================================
  // متدهای قدرتمند جعبه لایتنر شما (بدون تغییر و دست‌نخورده)
  // ==========================================
  Future<void> saveToPersonalFlashcards(
    WordAnalysis wordData, {
    String folder = 'General',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('کاربر لاگین نیست');

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
  }

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
