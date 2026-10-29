import 'dart:convert';

import 'package:lingo_sync/features/ai_dictionary/data/models/word_analysis_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../domain/entities/video_analysis.dart';
import '../../domain/repositories/i_video_analysis_repository.dart';
import '../models/video_analysis_dto.dart';
import '../services/ai_server_client.dart';

part 'video_analysis_repository_impl.g.dart';

@riverpod
IVideoAnalysisRepository videoAnalysisRepository(Ref ref) {
  return VideoAnalysisRepositoryImpl(
    Supabase.instance.client,
    ref.watch(aiServerClientProvider),
  );
}

class VideoAnalysisRepositoryImpl implements IVideoAnalysisRepository {
  final SupabaseClient _supabase;
  final AiServerClient _aiClient;

  VideoAnalysisRepositoryImpl(this._supabase, this._aiClient);

  String? _extractYoutubeVideoId(String url) {
    final regExp = RegExp(
      r"^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*",
    );
    final match = regExp.firstMatch(url);
    final group7 = match?.group(7);
    if (group7 != null && group7.length == 11) return group7;
    return null;
  }

  @override
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
            VideoAnalysisDto.fromJson(cachedData),
          );
        }
      }

      final response = await errorHandler.executeWithRetry(
        operation: () => _aiClient.postJson('/process_youtube', {
          'videoUrl': url,
        }, timeout: const Duration(seconds: 60)),
        context: 'VideoAnalysisRepositoryImpl.processYoutubeVideo',
      );

      final videoAnalysis = VideoAnalysisDto.fromJson(
        jsonDecode(response.body),
      );

      // Persist to Supabase Database
      await _supabase.from('video_analysis').upsert({
        'video_id': videoAnalysis.videoId,
        'summary': videoAnalysis.summary,
        'full_transcript_translation': videoAnalysis.fullTranscriptTranslation,
        'full_transcript': videoAnalysis.englishTranscript,
        'grammar_points': videoAnalysis.grammarPoints
            .map(
              (e) => {
                'structure_name': e.structureName,
                'persian_explanation': e.persianExplanation,
                'example_from_transcript': e.exampleFromTranscript,
              },
            )
            .toList(),
        'vocabulary': videoAnalysis.vocabulary
            .map((e) => WordAnalysisDto.toJson(e))
            .toList(),
      });

      return Result<VideoAnalysis>.success(videoAnalysis);
    } catch (e, st) {
      return Result<VideoAnalysis>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'VideoAnalysisRepositoryImpl.processYoutubeVideo',
        ),
      );
    }
  }

  @override
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
          context: 'VideoAnalysisRepositoryImpl.getAllGrammarVideos',
        ),
      );
    }
  }

  @override
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
          context: 'VideoAnalysisRepositoryImpl.loadUserNote',
        ),
      );
    }
  }

  @override
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
          context: 'VideoAnalysisRepositoryImpl.saveUserNote',
        ),
      );
    }
  }

  @override
  Future<Result<String>> askVideoAi(
    String videoId,
    String question, {
    bool useCouncil = false,
    String context = '',
  }) async {
    try {
      if (useCouncil) {
        final response = await errorHandler.executeWithRetry(
          operation: () => _aiClient.postJson('/multi_agent_consensus', {
            'question': question,
            'context': context,
          }, timeout: const Duration(seconds: 60)),
          context: 'VideoAnalysisRepositoryImpl.askMultiAgentConsensus',
        );
        final data = jsonDecode(response.body);
        final consensus = data['consensus'] as String? ?? 'پاسخی یافت نشد';
        return Result.success(consensus);
      }

      final response = await errorHandler.executeWithRetry(
        operation: () => _aiClient.postJson('/ask_video_ai', {
          'videoId': videoId,
          'question': question,
        }, timeout: const Duration(seconds: 30)),
        context: 'VideoAnalysisRepositoryImpl.askVideoAi',
      );

      final answer = jsonDecode(response.body)['answer'] as String;
      return Result.success(answer);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'VideoAnalysisRepositoryImpl.askVideoAi',
        ),
      );
    }
  }

  @override
  Future<Result<void>> processAllPendingVideos() async {
    try {
      final pendingTasks = await _supabase
          .from('daily_tasks')
          .select()
          .not('video_url', 'is', null)
          .eq('is_ai_processed', false);

      if (pendingTasks.isEmpty) {
        return Result.failure(
          const UnknownException('No tasks pending processing.'),
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
            context: 'VideoAnalysisRepositoryImpl.processAllPendingVideos',
          );
        }
      }

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'VideoAnalysisRepositoryImpl.processAllPendingVideos',
        ),
      );
    }
  }
}
