import 'package:lingo_sync/features/ai_dictionary/data/models/word_analysis_model.dart';

/// A single flashcard entry as shown to the user — the domain-level view
/// of a `flashcards` row joined with its `global_dictionary` entry.
///
/// This exists specifically to end the repeated pattern (previously
/// duplicated across `FlashcardsPage`, `AllFlashcardsPage`, and
/// `ArchiveCardTile`) of manually digging into a raw
/// `Map<String, dynamic>` — `card['global_dictionary']?['ai_analysis'] ??
/// card['ai_analysis'] ?? {}` — to account for the two historical shapes
/// a flashcard row can have (see `WordRepository.saveToPersonalFlashcards`'s
/// doc comment for why that split exists). That reconciliation now
/// happens in exactly one place: [FlashcardEntry.fromRow].
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

  /// Builds a [FlashcardEntry] from a raw Supabase row returned by
  /// `.select('*, global_dictionary(*)')` on the `flashcards` table.
  ///
  /// Reconciles the two historical shapes a row can be in:
  /// - Modern rows: `word_id` points at `global_dictionary`, whose
  ///   `ai_analysis` column holds the actual [WordAnalysis] JSON.
  /// - Legacy rows (grammar points saved before the schema was unified):
  ///   the analysis JSON lives directly on the flashcard row's own
  ///   `ai_analysis` column, with no `global_dictionary` join at all.
  factory FlashcardEntry.fromRow(Map<String, dynamic> row) {
    final globalDict = row['global_dictionary'] as Map<String, dynamic>?;
    final analysisJson =
        (globalDict?['ai_analysis'] as Map<String, dynamic>?) ??
        (row['ai_analysis'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    final word = WordAnalysis.fromJson(analysisJson);
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
