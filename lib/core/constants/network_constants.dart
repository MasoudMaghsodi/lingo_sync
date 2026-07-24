abstract final class NetworkConstants {
  // ========================
  // API Limits & Timeouts
  // ========================
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiShortTimeout = Duration(seconds: 10);
  static const Duration websocketTimeout = Duration(seconds: 15);
  static const Duration retryDelay = Duration(seconds: 2);

  static const int maxRetries = 3;
  static const int maxCriticalRetries = 5;
  static const int maxConcurrentRequests = 5;

  // ========================
  // Default Endpoints (Fallback)
  // ========================
  static const String supabaseUrl = 'https://jxqfgqjvjbgecczsfbyq.supabase.co';
  static const String videoServiceUrl = 'http://localhost:3002/analyze';
  static const String aiMentorUrl = 'ws://localhost:3003/mentor';
}
