/// Log severity levels for structured logging.
///
/// Follows standard logging conventions:
/// - debug: Detailed diagnostic information (development only)
/// - info: General informational messages (normal operation)
/// - warning: Warning messages (something unusual but recoverable)
/// - error: Error conditions (something went wrong, recovery possible)
/// - critical: Critical failures (system-level issues, crash-level)
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR'),
  critical(4, 'CRITICAL');

  final int value;
  final String label;

  const LogLevel(this.value, this.label);

  /// Check if this level should be logged given a minimum level
  bool shouldLog(LogLevel minLevel) => value >= minLevel.value;

  /// Get color code for console output (ANSI escape sequences)
  String get colorCode {
    return switch (this) {
      LogLevel.debug => '\x1B[36m', // Cyan
      LogLevel.info => '\x1B[32m', // Green
      LogLevel.warning => '\x1B[33m', // Yellow
      LogLevel.error => '\x1B[31m', // Red
      LogLevel.critical => '\x1B[41m', // Red background
    };
  }

  /// Get reset code for console output
  static const String colorReset = '\x1B[0m';
}
