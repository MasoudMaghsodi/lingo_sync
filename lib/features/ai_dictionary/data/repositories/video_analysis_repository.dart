import 'dart:convert';

import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/logging/app_logger.dart';
import 'package:lingo_sync/core/result/result.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../models/video_analysis_model.dart';
import '../services/ai_server_client.dart';

part 'video_analysis_repository.g.dart';

@riverpod
VideoAnalysisRepository videoAnalysisRepository(Ref ref) {
  return VideoAnalysisRepository(
    Supabase.instance.client,
    ref.watch(aiServerClientProvider),
  );
}

class VideoAnalysisRepository {
  final SupabaseClient _supabase;
  final AiServerClient _aiClient;

  VideoAnalysisRepository(this._supabase, this._aiClient);

  String? _extractYoutubeVideoId(String url) {
    final regExp = RegExp(
      r"^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*",
    );
    final match = regExp.firstMatch(url);
    final group7 = match?.group(7);
    if (group7 != null && group7.length == 11) return group7;
    return null;
  }

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
        operation: () => _aiClient.postJson('/process_youtube', {
          'videoUrl': url,
        }, timeout: const Duration(seconds: 60)),
        context: 'VideoAnalysisRepository.processYoutubeVideo',
      );

      final videoAnalysis = VideoAnalysis.fromJson(jsonDecode(response.body));

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
          context: 'VideoAnalysisRepository.processYoutubeVideo',
        ),
      );
    }
  }

  // ==========================================
  // متدهای جدید اضافه‌شده برای پاکسازی لایه UI
  // ==========================================

  /// دریافت تمامی گرامرهای استخراج‌شده از دیتابیس برای صفحه AllGrammarPage
  Future<Result<List<Map<String, dynamic>>>> getAllGrammarVideos() async {
    try {
      final response = await _supabase
          .from('video_analysis')
          .select('video_id, title, day_number, task_id, grammar_points')
          .order('day_number', ascending: true);

      final rows = List<Map<String, dynamic>>.from(response);

      final taskIds = rows
          .map((r) => r['task_id'])
          .whereType<int>()
          .toSet()
          .toList();
      final Map<int, String> taskTypesById = {};

      if (taskIds.isNotEmpty) {
        final tasksResponse = await _supabase
            .from('daily_tasks')
            .select('id, task_type')
            .inFilter('id', taskIds);
        for (final row in tasksResponse as List) {
          taskTypesById[row['id'] as int] = row['task_type'] as String;
        }
      }

      final result = rows.map((data) {
        data['task_type'] = data['task_id'] != null
            ? taskTypesById[data['task_id']]
            : null;
        return data;
      }).toList();

      return Result.success(result);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'VideoAnalysisRepository.getAllGrammarVideos',
        ),
      );
    }
  }

  /// بارگذاری یادداشت شخصی کاربر برای یک ویدیوی خاص
  Future<Result<String?>> loadUserNote(String videoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure(
        const AuthException('Not authenticated', code: 'not_authenticated'),
      );
    }

    try {
      final response = await _supabase
          .from('user_notes')
          .select('content')
          .eq('user_id', userId)
          .eq('reference_id', videoId)
          .maybeSingle();
      return Result.success(response?['content'] as String?);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'VideoAnalysisRepository.loadUserNote',
        ),
      );
    }
  }

  /// ذخیره یادداشت شخصی کاربر برای یک ویدیو
  Future<Result<void>> saveUserNote(String videoId, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure(
        const AuthException('Not authenticated', code: 'not_authenticated'),
      );
    }

    try {
      await _supabase.from('user_notes').upsert({
        'user_id': userId,
        'reference_id': videoId,
        'note_type': 'video',
        'content': content,
      });
      return Result.success(null);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'VideoAnalysisRepository.saveUserNote',
        ),
      );
    }
  }

  /// پرسش از هوش مصنوعی با استفاده از کلاینت استاندارد (به جای http مستقیم)
  Future<Result<String>> askVideoAi(String videoId, String question) async {
    try {
      final response = await errorHandler.executeWithRetry(
        operation: () => _aiClient.postJson('/ask_video_ai', {
          'videoId': videoId,
          'question': question,
        }, timeout: const Duration(seconds: 30)),
        context: 'VideoAnalysisRepository.askVideoAi',
      );

      final answer = jsonDecode(response.body)['answer'] as String;
      return Result.success(answer);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'VideoAnalysisRepository.askVideoAi',
        ),
      );
    }
  }

  /// پردازش گروهی تمام ویدیوهای تسک‌های روزانه که هنوز توسط هوش مصنوعی بررسی نشده‌اند
  Future<Result<void>> processAllPendingVideos() async {
    try {
      final pendingTasks = await _supabase
          .from('daily_tasks')
          .select()
          .not('video_url', 'is', null)
          .eq('is_ai_processed', false);

      if (pendingTasks.isEmpty) {
        return Result.failure(
          const UnknownException('تمام ویدیوها پردازش شده‌اند.'),
        );
      }

      for (final task in pendingTasks) {
        final videoUrl = task['video_url'] as String;
        final taskId = task['id'] as int;

        try {
          final result = await processYoutubeVideo(videoUrl);
          if (result.isSuccess()) {
            await _supabase
                .from('daily_tasks')
                .update({'is_ai_processed': true})
                .eq('id', taskId);
          }
        } catch (e) {
          logger.warning(
            'Skipped automated task $taskId',
            context: 'VideoAnalysisRepository.processAllPendingVideos',
          );
        }
      }
      return Result.success(null);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'VideoAnalysisRepository.processAllPendingVideos',
        ),
      );
    }
  }
}
