import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lingo_sync/core/result/result.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';
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

/// Owns YouTube video processing (transcript analysis, grammar/vocabulary
/// extraction). Split out of the old God-object `DictionaryRepository`,
/// which mixed this in with word lookups and the offline flashcard cache.
class VideoAnalysisRepository {
  final SupabaseClient _supabase;
  final AiServerClient _aiClient;

  VideoAnalysisRepository(this._supabase, this._aiClient);

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
          context: 'VideoAnalysisRepository.processYoutubeVideo',
        ),
      );
    }
  }
}
