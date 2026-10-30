import '../../../../core/utils/map_utils.dart';
import '../../domain/entities/video_analysis.dart';
import 'word_analysis_dto.dart';

class VideoAnalysisDto {
  static GrammarPoint grammarFromJson(dynamic rawJson) {
    final json = safeMap(rawJson);
    return GrammarPoint(
      structureName: json['structure_name']?.toString() ?? '',
      persianExplanation: json['persian_explanation']?.toString() ?? '',
      exampleFromTranscript: json['example_from_transcript']?.toString() ?? '',
    );
  }

  static VideoAnalysis fromJson(dynamic rawJson) {
    final json = safeMap(rawJson);
    final grammarList = json['grammar_points'] is List
        ? (json['grammar_points'] as List)
        : [];
    final vocabList = json['vocabulary'] is List
        ? (json['vocabulary'] as List)
        : [];

    final englishTranscript =
        json['full_transcript']?.toString() ??
        json['english_transcript']?.toString() ??
        json['raw_transcript']?.toString() ??
        '';

    return VideoAnalysis(
      videoId: json['video_id']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      fullTranscriptTranslation:
          json['full_transcript_translation']?.toString() ?? '',
      englishTranscript: englishTranscript,
      grammarPoints: grammarList.whereType<Map>().map(grammarFromJson).toList(),
      vocabulary: vocabList
          .whereType<Map>()
          .map(WordAnalysisDto.fromJson)
          .toList(),
    );
  }
}
