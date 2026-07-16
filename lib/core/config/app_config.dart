// ignore_for_file: unintended_html_in_doc_comment

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';

/// Single point of access for every value that comes from `.env`.
///
/// Nothing in the app should call `dotenv.env[...]` directly anymore —
/// that scatters config keys across the codebase and makes it easy to
/// hardcode a fallback URL/IP "just this once". Every environment-derived
/// value the app needs has its own named getter here instead.
///
/// Throws [ConfigException] if a required key is missing, which surfaces
/// clearly at startup instead of failing later with a cryptic null-check
/// error deep inside a repository.
abstract class AppConfig {
  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw ConfigException(
        'Missing required environment variable: $key. '
        'Add it to your .env file (see .env.example).',
        configKey: key,
      );
    }
    return value;
  }

  /// Supabase project URL.
  static String get supabaseUrl => _require('SUPABASE_URL');

  /// Supabase publishable/anon key.
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  /// Base URL for the AI Express backend (word/video analysis, AI Q&A).
  /// Example: http://<host>:3002/api
  static String get aiServerBaseUrl => _require('AI_SERVER_BASE_URL');

  /// WebSocket URL for the live AI Mentor voice session.
  /// Example: wss://<host>/ws
  static String get mentorSocketUrl => _require('MENTOR_SOCKET_URL');
}
