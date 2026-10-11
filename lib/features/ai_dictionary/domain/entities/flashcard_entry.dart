import 'word_analysis.dart';

class FlashcardEntry {
  final int id;
  final int? wordId;
  final String word;
  final String partOfSpeech;
  final String englishMeaning;
  final String persianMeaning;
  final List<String> examples;
  final Map<String, WordDetail> synonymsByLevel;
  final String folderName;
  final int repetition;
  final int interval;
  final double easeFactor;
  final DateTime nextReviewDate;

  const FlashcardEntry({
    required this.id,
    required this.wordId,
    required this.word,
    required this.partOfSpeech,
    required this.englishMeaning,
    required this.persianMeaning,
    required this.examples,
    required this.synonymsByLevel,
    required this.folderName,
    required this.repetition,
    required this.interval,
    required this.easeFactor,
    required this.nextReviewDate,
  });
}
