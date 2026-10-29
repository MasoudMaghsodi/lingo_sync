import '../../../../core/utils/map_utils.dart';
import '../../domain/entities/flashcard_entry.dart';
import 'word_analysis_dto.dart';

class FlashcardEntryDto {
  static FlashcardEntry fromRow(dynamic rawRow) {
    final row = safeMap(rawRow);
    final globalDict = safeMap(row['global_dictionary']);
    final analysisJson = safeMap(
      globalDict.isNotEmpty && globalDict['ai_analysis'] != null
          ? globalDict['ai_analysis']
          : row['ai_analysis'],
    );

    final word = WordAnalysisDto.fromJson(analysisJson);
    final resolvedWordText = word.word.isNotEmpty
        ? word.word
        : (globalDict['word']?.toString().isNotEmpty == true
            ? globalDict['word'].toString()
            : (row['word']?.toString() ?? 'Unknown'));

    return FlashcardEntry(
      id: (row['id'] as num?)?.toInt() ?? 0,
      wordId: (row['word_id'] as num?)?.toInt(),
      word: resolvedWordText,
      partOfSpeech: word.partOfSpeech,
      englishMeaning: word.englishMeaning,
      persianMeaning: word.persianMeaning,
      examples: word.examples,
      synonymsByLevel: word.synonymsByLevel,
      folderName: row['folder_name']?.toString() ?? 'General',
      repetition: (row['repetition'] as num?)?.toInt() ?? 0,
      interval: (row['interval'] as num?)?.toInt() ?? 0,
      easeFactor: (row['ease_factor'] as num?)?.toDouble() ?? 2.5,
      nextReviewDate:
          DateTime.tryParse(row['next_review_date']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
