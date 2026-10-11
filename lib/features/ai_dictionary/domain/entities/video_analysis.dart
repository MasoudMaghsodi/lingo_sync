import 'word_analysis.dart';

class GrammarPoint {
  final String structureName;
  final String persianExplanation;
  final String exampleFromTranscript;

  const GrammarPoint({
    required this.structureName,
    required this.persianExplanation,
    required this.exampleFromTranscript,
  });
}

class VideoAnalysis {
  final String videoId;
  final String summary;
  final String fullTranscriptTranslation;
  final List<GrammarPoint> grammarPoints;
  final List<WordAnalysis> vocabulary;

  const VideoAnalysis({
    required this.videoId,
    required this.summary,
    required this.fullTranscriptTranslation,
    required this.grammarPoints,
    required this.vocabulary,
  });
}
