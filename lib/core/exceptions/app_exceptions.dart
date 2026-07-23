/// Sealed exception hierarchy for structured error handling.
///
/// This replaces silent catch handlers and provides type-safe error handling
/// across the entire application. Each exception type represents a specific
/// failure domain (auth, network, validation, etc.).
///
/// Example usage:
/// ```dart
/// try {
///   await repository.login(email, password);
/// } on AuthException catch (e) {
///   print('Auth failed: ${e.message}');
/// } on NetworkException catch (e) {
///   print('Network error: ${e.statusCode}');
/// } on AppException catch (e) {
///   print('Unexpected error: ${e.message}');
/// }
/// ```
sealed class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  const AppException(this.message, [this.stackTrace]);

  @override
  String toString() => 'AppException: $message';
}

/// Authentication-related exceptions (login, signup, token refresh, etc.)
///
/// Represents failures in authentication operations including invalid
/// credentials, session expiry, or account restrictions.
final class AuthException extends AppException {
  /// Optional error code from auth service (e.g., 'invalid_credentials')
  final String? code;

  const AuthException(String message, {this.code, StackTrace? stackTrace})
    : super(message, stackTrace);

  @override
  String toString() =>
      'AuthException${code != null ? '($code)' : ''}: $message';
}

/// Network-related exceptions (timeouts, connection failures, etc.)
///
/// Represents failures in network communication including connectivity issues,
/// DNS failures, SSL errors, and HTTP error responses.
final class NetworkException extends AppException {
  /// HTTP status code if applicable (e.g., 404, 500)
  final int? statusCode;

  /// Retry-able flag: true if operation can be retried
  final bool isRetryable;

  const NetworkException(
    String message, {
    this.statusCode,
    this.isRetryable = true,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() =>
      'NetworkException${statusCode != null ? '($statusCode)' : ''}: $message';
}

/// Validation exceptions (invalid input, constraint violations)
///
/// Represents failures in data validation including missing required fields,
/// format violations, and business rule constraints.
final class ValidationException extends AppException {
  /// Field name that failed validation (e.g., 'email', 'password')
  final String? fieldName;

  /// Specific validation rule that was violated
  final String? validationRule;

  const ValidationException(
    String message, {
    this.fieldName,
    this.validationRule,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() =>
      'ValidationException${fieldName != null ? '($fieldName)' : ''}: $message';
}

/// Database-related exceptions (query failures, constraint violations, etc.)
///
/// Represents failures in database operations including query errors,
/// constraint violations, and data consistency issues.
final class DatabaseException extends AppException {
  /// Name of the database operation that failed (e.g., 'insert', 'update')
  final String? operation;

  /// Name of the table affected
  final String? tableName;

  const DatabaseException(
    String message, {
    this.operation,
    this.tableName,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() =>
      'DatabaseException${operation != null ? '($operation)' : ''}: $message';
}

/// Cache-related exceptions (miss, eviction, serialization errors)
///
/// Represents failures in caching operations including cache misses,
/// deserialization errors, and cache corruption.
final class CacheException extends AppException {
  /// Cache key that failed to retrieve or store
  final String? cacheKey;

  const CacheException(String message, {this.cacheKey, StackTrace? stackTrace})
    : super(message, stackTrace);

  @override
  String toString() => 'CacheException: $message';
}

/// File system-related exceptions (I/O errors, permissions, etc.)
///
/// Represents failures in file operations including read/write errors,
/// permission issues, and missing files.
final class FileException extends AppException {
  /// Path to the file that caused the error
  final String? filePath;

  /// Type of file operation that failed ('read', 'write', 'delete')
  final String? operation;

  const FileException(
    String message, {
    this.filePath,
    this.operation,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() =>
      'FileException${operation != null ? '($operation)' : ''}: $message';
}

/// Permission-related exceptions (unauthorized access, insufficient privileges)
///
/// Represents security failures including authentication failures,
/// insufficient permissions, and policy violations.
final class PermissionException extends AppException {
  /// Resource that requires permission
  final String? resource;

  /// Required permission level
  final String? requiredPermission;

  const PermissionException(
    String message, {
    this.resource,
    this.requiredPermission,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() => 'PermissionException: $message';
}

/// API-specific exceptions (malformed response, parsing errors)
///
/// Represents failures specific to API operations including malformed responses,
/// invalid data formats, and protocol violations.
final class ApiException extends AppException {
  /// URL of the API endpoint that failed
  final String? endpoint;

  /// Response status code if available
  final int? statusCode;

  /// Parsed error response from the API
  final dynamic errorResponse;

  const ApiException(
    String message, {
    this.endpoint,
    this.statusCode,
    this.errorResponse,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() =>
      'ApiException${statusCode != null ? '($statusCode)' : ''}: $message';
}

/// State management exceptions (invalid transitions, illegal operations)
///
/// Represents failures in state management operations including
/// invalid state transitions and illegal state operations.
final class StateException extends AppException {
  /// Current state that caused the error
  final String? currentState;

  /// Attempted operation
  final String? attemptedOperation;

  const StateException(
    String message, {
    this.currentState,
    this.attemptedOperation,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() => 'StateException: $message';
}

/// Configuration exceptions (missing config, invalid values)
///
/// Represents failures in application configuration including
/// missing required config values and invalid configuration.
final class ConfigException extends AppException {
  /// Name of the configuration key that is missing or invalid
  final String? configKey;

  const ConfigException(
    String message, {
    this.configKey,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() => 'ConfigException: $message';
}

/// WebSocket-related exceptions (connection, handshake, message errors)
///
/// Represents failures in WebSocket operations including connection failures,
/// handshake errors, and message transmission failures.
final class WebSocketException extends AppException {
  /// Code of the WebSocket close frame (if applicable)
  final int? closeCode;

  /// Reason for WebSocket closure
  final String? closeReason;

  const WebSocketException(
    String message, {
    this.closeCode,
    this.closeReason,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() =>
      'WebSocketException${closeCode != null ? '($closeCode)' : ''}: $message';
}

/// Timeout exceptions (operation took too long)
///
/// Represents failures due to operation timeouts.
final class TimeoutException extends AppException {
  /// Operation that timed out
  final String? operation;

  /// Timeout duration
  final Duration? duration;

  const TimeoutException(
    String message, {
    this.operation,
    this.duration,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Unknown/unexpected exceptions
///
/// Represents unexpected failures that don't fit other categories.
/// Should be used as a fallback for truly unexpected errors.
final class UnknownException extends AppException {
  /// Original exception if available
  final dynamic originalException;

  const UnknownException(
    String message, {
    this.originalException,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);

  @override
  String toString() => 'UnknownException: $message';
}
