import '../../../../../core/result/result.dart';
import '../entities/word_analysis.dart';

abstract class IWordRepository {
  /// Analyzes a word using the AI Server
  Future<Result<WordAnalysis>> fetchWordAnalysis(String word);

  /// Saves a word to the user's personal flashcards in a specific folder
  Future<Result<void>> saveToPersonalFlashcards(
    WordAnalysis wordData, {
    String folder = 'General',
  });

  /// Allows the user to manually add a custom word without AI analysis
  Future<Result<void>> addCustomWordManually(
    WordAnalysis customWord, {
    String folder = 'General',
  });
}
