import 'word_analysis_model.dart';

class VideoAnalysis {
  final String videoId;
  final String summary;
  final String fullTranscriptTranslation; // 🚀 اضافه شد
  final List<GrammarPoint> grammarPoints;
  final List<WordAnalysis> vocabulary;

  VideoAnalysis({
    required this.videoId,
    required this.summary,
    required this.fullTranscriptTranslation,
    required this.grammarPoints,
    required this.vocabulary,
  });

  factory VideoAnalysis.fromJson(Map<String, dynamic> json) {
    return VideoAnalysis(
      videoId: json['video_id'] ?? '',
      summary: json['summary'] ?? '',
      fullTranscriptTranslation:
          json['full_transcript_translation'] ?? 'ترجمه‌ای یافت نشد',
      grammarPoints:
          (json['grammar_points'] as List?)
              ?.map((e) => GrammarPoint.fromJson(e))
              .toList() ??
          [],
      vocabulary:
          (json['vocabulary'] as List?)
              ?.map((e) => WordAnalysis.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class GrammarPoint {
  final String structureName;
  final String persianExplanation; // 🚀 این حالا به زبان کودکانه است
  final String exampleFromTranscript;

  GrammarPoint({
    required this.structureName,
    required this.persianExplanation,
    required this.exampleFromTranscript,
  });

  factory GrammarPoint.fromJson(Map<String, dynamic> json) {
    return GrammarPoint(
      structureName: json['structure_name'] ?? '',
      persianExplanation: json['persian_explanation'] ?? '',
      exampleFromTranscript: json['example_from_transcript'] ?? '',
    );
  }
}
