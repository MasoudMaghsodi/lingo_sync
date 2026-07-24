abstract final class BusinessConstants {
  // ========================
  // App Metadata
  // ========================
  static const String appVersion = '1.0.0';

  // ========================
  // Session & Limits
  // ========================
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration tokenRefreshInterval = Duration(minutes: 5);

  static const int maxNameLength = 100;
  static const int maxWordLength = 50;
  static const int maxTranslationLength = 500;
  static const int maxNoteLength = 1000;
  static const int maxFlashcardsPerRequest = 100;
  static const int maxDailyTasks = 50;

  // ========================
  // English Levels & Task Types
  // ========================
  static const String minEnglishLevel = 'A1';
  static const String maxEnglishLevel = 'C2';
  static const List<String> englishLevels = [
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
  ];

  static const String taskTypeListening = 'listening';
  static const String taskTypeReading = 'reading';
  static const String taskTypeGrammar = 'grammar';
  static const String taskTypeVocabulary = 'vocabulary';
  static const String taskTypeWriting = 'writing';
  static const String taskTypeSpeaking = 'speaking';
  static const List<String> taskTypes = [
    taskTypeListening,
    taskTypeReading,
    taskTypeGrammar,
    taskTypeVocabulary,
    taskTypeWriting,
    taskTypeSpeaking,
  ];

  // ========================
  // Spaced Repetition (SM-2)
  // ========================
  static const int reviewIntervalBox1 = 1;
  static const int reviewIntervalBox2 = 3;
  static const int reviewIntervalBox3 = 7;
  static const int reviewIntervalBox4 = 14;
  static const int reviewIntervalBox5 = 30;

  static const double initialEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;
  static const double maxEaseFactor = 10.0;

  // ========================
  // Validation Regex
  // ========================
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String passwordRegex =
      r'^(?=.*?[A-Z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,20}$';
}
