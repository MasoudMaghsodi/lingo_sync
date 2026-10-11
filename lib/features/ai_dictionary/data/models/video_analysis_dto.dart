import '../../domain/entities/video_analysis.dart';
import 'word_analysis_dto.dart';

class VideoAnalysisDto {
  static GrammarPoint grammarFromJson(Map<String, dynamic> json) {
    return GrammarPoint(
      structureName: json['structure_name'] ?? '',
      persianExplanation: json['persian_explanation'] ?? '',
      exampleFromTranscript: json['example_from_transcript'] ?? '',
    );
  }

  static VideoAnalysis fromJson(Map<String, dynamic> json) {
    return VideoAnalysis(
      videoId: json['video_id'] ?? '',
      summary: json['summary'] ?? '',
      fullTranscriptTranslation: json['full_transcript_translation'] ?? '',
      grammarPoints:
          (json['grammar_points'] as List?)
              ?.map((e) => grammarFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      vocabulary:
          (json['vocabulary'] as List?)
              ?.map((e) => WordAnalysisDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
