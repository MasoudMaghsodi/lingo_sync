import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:lingo_sync/core/logging/log_entry.dart';
import 'package:lingo_sync/core/logging/log_level.dart';

/// Global logger instance - accessed anywhere with `logger`
late final AppLogger logger;

/// Central logging service for the entire application.
///
/// Features:
/// - Structured logging with multiple severity levels
/// - Console output in development, silent in production
/// - Automatic stack trace capture
/// - Contextual information (where the error occurred)
/// - Optional metadata for debugging
///
/// Usage:
/// ```dart
/// logger.info('User logged in', data: {'userId': user.id});
/// logger.warning('High memory usage', context: 'Dashboard');
/// logger.error('Database connection failed', error: exception);
/// logger.critical('Unrecoverable state', error: exception, stackTrace: stackTrace);
/// ```
class AppLogger {
  /// Minimum log level to output
  /// In debug mode: LogLevel.debug (all logs)
  /// In release mode: LogLevel.info (skip debug logs)
  final LogLevel minimumLevel;

  /// Whether to print to console (development)
  final bool enableConsoleOutput;

  /// List of all log entries (useful for debugging)
  final List<LogEntry> _history = [];

  /// Maximum number of log entries to keep in memory
  static const int maxHistorySize = 1000;

  AppLogger({LogLevel? minimumLevel, bool? enableConsoleOutput})
    : minimumLevel =
          minimumLevel ?? (kDebugMode ? LogLevel.debug : LogLevel.info),
      enableConsoleOutput = enableConsoleOutput ?? kDebugMode;

  /// Log debug message (development only)
  void debug(String message, {String? context, Map<String, dynamic>? data}) {
    _log(level: LogLevel.debug, message: message, context: context, data: data);
  }

  /// Log info message (normal operation)
  void info(String message, {String? context, Map<String, dynamic>? data}) {
    _log(level: LogLevel.info, message: message, context: context, data: data);
  }

  /// Log warning message (something unusual but recoverable)
  void warning(
    String message, {
    String? context,
    Exception? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      level: LogLevel.warning,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log error message (something went wrong)
  void error(
    String message, {
    String? context,
    Exception? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      level: LogLevel.error,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log critical error (crash-level issue)
  void critical(
    String message, {
    String? context,
    Exception? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      level: LogLevel.critical,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Internal logging method
  void _log({
    required LogLevel level,
    required String message,
    String? context,
    Exception? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Check if this level should be logged
    if (!level.shouldLog(minimumLevel)) return;

    // Create log entry
    final entry = LogEntry(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      data: data,
    );

    // Store in history
    _addToHistory(entry);

    // Console output (development only)
    if (enableConsoleOutput) {
      _printToConsole(entry);
    }

    // Native logging (useful for device logs)
    developer.log(
      message,
      level: _levelToValue(level),
      name: context ?? 'App',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Print to console with formatting
  void _printToConsole(LogEntry entry) {
    debugPrint(entry.toConsoleString());
  }

  /// Convert LogLevel to developer.log level value
  int _levelToValue(LogLevel level) {
    return switch (level) {
      LogLevel.debug => 200,
      LogLevel.info => 800,
      LogLevel.warning => 900,
      LogLevel.error => 1000,
      LogLevel.critical => 1200,
    };
  }

  /// Add entry to history with size limit
  void _addToHistory(LogEntry entry) {
    _history.add(entry);
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }
  }

  /// Get all log entries from history
  List<LogEntry> getHistory() => List.unmodifiable(_history);

  /// Clear log history
  void clearHistory() {
    _history.clear();
  }

  /// Get logs of specific level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _history.where((entry) => entry.level == level).toList();
  }

  /// Get logs from specific context
  List<LogEntry> getLogsByContext(String context) {
    return _history.where((entry) => entry.context == context).toList();
  }

  /// Export all logs as JSON (useful for crash reporting)
  List<Map<String, dynamic>> exportAsJson() {
    return _history.map((entry) => entry.toJson()).toList();
  }

  /// Export all logs as formatted string
  String exportAsText() {
    return _history.map((entry) => entry.toConsoleString()).join('\n\n');
  }
}

/// Initialize the global logger
void initializeLogger({LogLevel? minimumLevel, bool? enableConsoleOutput}) {
  logger = AppLogger(
    minimumLevel: minimumLevel,
    enableConsoleOutput: enableConsoleOutput,
  );
}
