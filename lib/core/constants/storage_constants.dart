abstract final class StorageConstants {
  // ========================
  // Shared Preferences Keys
  // ========================
  static const String prKeyUserId = 'user_id';
  static const String prKeyUserEmail = 'user_email';
  static const String prKeyUserLevel = 'user_level';
  static const String prKeyIsApproved = 'is_approved';
  static const String prKeyCurrentDay = 'current_day';
  static const String prKeyStreak = 'streak_days';
  static const String prKeyLastActive = 'last_active';
  static const String prKeyThemeMode = 'theme_mode';
  static const String prKeyLanguage = 'language';

  // ========================
  // Hive Boxes
  // ========================
  static const String hiveBoxFlashcards = 'flashcards';
  static const String hiveBoxUserNotes = 'user_notes';
  static const String hiveBoxCache = 'app_cache';
}
