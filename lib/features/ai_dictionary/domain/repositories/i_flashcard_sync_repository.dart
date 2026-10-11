import '../../../../../core/result/result.dart';
import '../entities/flashcard_entry.dart';

abstract class IFlashcardSyncRepository {
  List<FlashcardEntry> getCachedDueFlashcards(String userId);
  Future<bool> refreshDueFlashcardsFromRemote(String userId);
  Future<void> updateFlashcardReview({
    required String userId,
    required int flashcardId,
    required int quality,
    required Map<String, dynamic> updatedData,
  });
  Future<bool> syncPendingActions();
  Future<Result<List<FlashcardEntry>>> getAllFlashcards();

  /// Renames a folder. Throws an error if the folder is 'General' or 'Grammar'.
  Future<Result<void>> renameFolder(String oldName, String newName);

  /// Deletes a folder and moves its cards. Throws an error if the folder is 'General' or 'Grammar'.
  Future<Result<void>> deleteFolder(String folderName);

  Future<Result<void>> moveFlashcard(int flashcardId, String newFolder);
}
