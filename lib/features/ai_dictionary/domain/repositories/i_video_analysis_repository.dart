import '../../../../../core/result/result.dart';
import '../entities/video_analysis.dart';

abstract class IVideoAnalysisRepository {
  /// Processes a YouTube video through the AI Express server
  Future<Result<VideoAnalysis>> processYoutubeVideo(String url);

  /// Fetches all grammar-related videos for the AllGrammarPage
  Future<Result<List<Map<String, dynamic>>>> getAllGrammarVideos();

  /// Loads the user's personal note for a specific video
  Future<Result<String?>> loadUserNote(String videoId);

  /// Saves the user's personal note to Supabase
  Future<Result<void>> saveUserNote(String videoId, String content);

  /// Asks a question to the AI mentor regarding the video transcript
  Future<Result<String>> askVideoAi(String videoId, String question);

  /// Automatically processes all pending videos in the background (Cron-like behavior)
  Future<Result<void>> processAllPendingVideos();
}
