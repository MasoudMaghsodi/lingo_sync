import 'package:lingo_sync/core/logging/log_level.dart';

/// Data model for a single log entry.
///
/// Represents a structured log record with timestamp, level, message,
/// error information, and optional metadata.
class LogEntry {
  /// Log level (debug, info, warning, error, critical)
  final LogLevel level;

  /// Main message
  final String message;

  /// Associated exception (if any)
  final Exception? error;

  /// Stack trace of the error
  final StackTrace? stackTrace;

  /// Timestamp when log was created
  final DateTime timestamp;

  /// Optional context for where the error occurred
  /// Example: 'AuthRepository.signUp', 'DictionaryPage.build'
  final String? context;

  /// Additional metadata as key-value pairs
  /// Example: {'userId': '123', 'retryCount': 2}
  final Map<String, dynamic>? data;

  LogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.context,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON-serializable map
  Map<String, dynamic> toJson() {
    return {
      'level': level.label,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      if (context != null) 'context': context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      if (data != null) 'data': data,
    };
  }

  /// Format for console output
  String toConsoleString() {
    final buffer = StringBuffer();

    buffer.write('${level.colorCode}[${level.label}]${LogLevel.colorReset} ');
    buffer.write(
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')} ',
    );

    if (context != null) {
      buffer.write('[$context] ');
    }

    buffer.write(message);

    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    if (data != null && data!.isNotEmpty) {
      buffer.write('\n  Data: ');
      data!.forEach((key, value) {
        buffer.write('$key=$value, ');
      });
    }

    return buffer.toString();
  }

  @override
  String toString() => toConsoleString();
}
