/// Central repository for all application constants.
/// 
/// This file contains hardcoded values like durations, timeouts, sizes, and API URLs.
/// Using constants instead of magic numbers improves maintainability and consistency.
abstract class AppConstants {
  // ========================
  // Duration Constants
  // ========================

  /// Duration for main API operations (30 seconds)
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Duration for shorter API calls like health checks (10 seconds)
  static const Duration apiShortTimeout = Duration(seconds: 10);

  /// Duration for page transitions and animations (300ms)
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Duration for shorter animations like button taps (150ms)
  static const Duration quickAnimationDuration = Duration(milliseconds: 150);

  /// Debounce delay for search and input validation (500ms)
  static const Duration debounceDelay = Duration(milliseconds: 500);

  /// Splash screen display time (2 seconds)
  static const Duration splashDuration = Duration(seconds: 2);

  /// WebSocket connection timeout (15 seconds)
  static const Duration websocketTimeout = Duration(seconds: 15);

  /// Retry delay for failed API calls (2 seconds)
  static const Duration retryDelay = Duration(seconds: 2);

  /// Session timeout - user logged out if inactive (30 minutes)
  static const Duration sessionTimeout = Duration(minutes: 30);

  /// Refresh token interval (5 minutes before expiry)
  static const Duration tokenRefreshInterval = Duration(minutes: 5);

  // ========================
  // Size Constants
  // ========================

  /// Standard padding for UI elements (16 pixels)
  static const double standardPadding = 16.0;

  /// Small padding for compact layouts (8 pixels)
  static const double smallPadding = 8.0;

  /// Large padding for spacious layouts (24 pixels)
  static const double largePadding = 24.0;

  /// Extra large padding (32 pixels)
  static const double extraLargePadding = 32.0;

  /// Standard border radius (12 pixels)
  static const double standardBorderRadius = 12.0;

  /// Small border radius (4 pixels)
  static const double smallBorderRadius = 4.0;

  /// Large border radius (20 pixels)
  static const double largeBorderRadius = 20.0;

  /// Standard icon size (24 pixels)
  static const double standardIconSize = 24.0;

  /// Large icon size (48 pixels)
  static const double largeIconSize = 48.0;

  /// Small icon size (16 pixels)
  static const double smallIconSize = 16.0;

  /// Standard app bar height (56 pixels)
  static const double appBarHeight = 56.0;

  /// Bottom navigation height (56 pixels)
  static const double bottomNavHeight = 56.0;

  /// Maximum width for card-based layouts (500 pixels)
  static const double maxCardWidth = 500.0;

  // ========================
  // Retry & Error Handling
  // ========================

  /// Maximum number of retry attempts for API calls
  static const int maxRetries = 3;

  /// Maximum number of retry attempts for critical operations
  static const int maxCriticalRetries = 5;

  /// Maximum concurrent API requests
  static const int maxConcurrentRequests = 5;

  // ========================
  // Data Limits
  // ========================

  /// Maximum length for user's full name (100 characters)
  static const int maxNameLength = 100;

  /// Maximum length for a single word (50 characters)
  static const int maxWordLength = 50;

  /// Maximum length for word translations (500 characters)
  static const int maxTranslationLength = 500;

  /// Maximum length for user notes (1000 characters)
  static const int maxNoteLength = 1000;

  /// Maximum number of flashcards per request
  static const int maxFlashcardsPerRequest = 100;

  /// Maximum number of daily tasks
  static const int maxDailyTasks = 50;

  /// Minimum English level requirement
  static const String minEnglishLevel = 'A1';

  /// Maximum English level
  static const String maxEnglishLevel = 'C2';

  // ========================
  // Cache Constants
  // ========================

  /// Cache expiration time (24 hours)
  static const Duration cacheExpiration = Duration(hours: 24);

  /// Flashcard cache expiration (1 hour)
  static const Duration flashcardCacheExpiration = Duration(hours: 1);

  /// User stats cache expiration (5 minutes)
  static const Duration userStatsCacheExpiration = Duration(minutes: 5);

  /// Maximum cache size in MB
  static const int maxCacheSizeMB = 100;

  // ========================
  // English Levels (CEFR)
  // ========================

  static const List<String> englishLevels = [
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
  ];

  // ========================
  // Task Types
  // ========================

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
  // Flashcard Limits
  // ========================

  /// Number of days between reviews for box 1
  static const int reviewIntervalBox1 = 1;

  /// Number of days between reviews for box 2
  static const int reviewIntervalBox2 = 3;

  /// Number of days between reviews for box 3
  static const int reviewIntervalBox3 = 7;

  /// Number of days between reviews for box 4
  static const int reviewIntervalBox4 = 14;

  /// Number of days between reviews for box 5
  static const int reviewIntervalBox5 = 30;

  /// Initial SM-2 ease factor for spaced repetition
  static const double initialEaseFactor = 2.5;

  /// Minimum ease factor allowed
  static const double minEaseFactor = 1.3;

  /// Maximum ease factor allowed
  static const double maxEaseFactor = 10.0;

  // ========================
  // API Endpoints (Environment-based)
  // ========================

  /// Base URL for Supabase API (from environment or default)
  static const String supabaseUrl = 'https://jxqfgqjvjbgecczsfbyq.supabase.co';

  /// Video analysis service URL
  static const String videoServiceUrl = 'http://localhost:3002/analyze';

  /// AI Mentor service URL
  static const String aiMentorUrl = 'ws://localhost:3003/mentor';

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

  // ========================
  // Empty / Default Values
  // ========================

  static const String emptyString = '';
  static const int defaultScore = 0;
  static const int defaultCurrentDay = 1;
  static const int defaultStreak = 0;

  // ========================
  // Regular Expressions
  // ========================

  /// Email validation pattern
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  /// Password pattern - at least 8 chars, 1 uppercase, 1 number, 1 special char
  static const String passwordRegex =
      r'^(?=.*?[A-Z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';

  /// Username pattern - alphanumeric and underscore only
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,20}$';
}
