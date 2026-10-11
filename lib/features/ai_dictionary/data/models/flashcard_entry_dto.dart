import '../../domain/entities/flashcard_entry.dart';
import 'word_analysis_dto.dart';

class FlashcardEntryDto {
  static FlashcardEntry fromRow(Map<String, dynamic> row) {
    final globalDict = row['global_dictionary'] as Map<String, dynamic>?;
    final analysisJson =
        (globalDict?['ai_analysis'] as Map<String, dynamic>?) ??
        (row['ai_analysis'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    final word = WordAnalysisDto.fromJson(analysisJson);
    final resolvedWordText = word.word.isNotEmpty
        ? word.word
        : (globalDict?['word'] as String? ?? 'Unknown');

    return FlashcardEntry(
      id: row['id'] as int,
      wordId: row['word_id'] as int?,
      word: resolvedWordText,
      partOfSpeech: word.partOfSpeech,
      englishMeaning: word.englishMeaning,
      persianMeaning: word.persianMeaning,
      examples: word.examples,
      synonymsByLevel: word.synonymsByLevel,
      folderName: row['folder_name'] as String? ?? 'General',
      repetition: (row['repetition'] as num?)?.toInt() ?? 0,
      interval: (row['interval'] as num?)?.toInt() ?? 0,
      easeFactor: (row['ease_factor'] as num?)?.toDouble() ?? 2.5,
      nextReviewDate:
          DateTime.tryParse(row['next_review_date'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
