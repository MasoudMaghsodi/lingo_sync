import 'package:lingo_sync/core/exceptions/app_exceptions.dart';

/// Type-safe result wrapper combining success and failure into one type.
///
/// This sealed class eliminates the need for nullable types and multiple
/// return values, providing a unified way to handle both success and failure.
///
/// Example usage:
/// ```dart
/// Result<User> result = await userRepository.getUser(id);
/// 
/// result.when(
///   success: (user) => print('User: ${user.name}'),
///   failure: (error) => print('Error: ${error.message}'),
/// );
/// ```
sealed class Result<T> {
  const Result();

  /// Create a successful result
  factory Result.success(T data) = Success<T>;

  /// Create a failed result
  factory Result.failure(AppException exception) = Failure<T>;

  /// Execute logic based on result type
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final exception) => failure(exception),
    };
  }

  /// Execute side effects based on result type
  Future<void> whenAsync({
    required Future<void> Function(T data) success,
    required Future<void> Function(AppException exception) failure,
  }) async {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final exception) => failure(exception),
    };
  }

  /// Map success value to another type
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => Result.success(transform(data)),
      Failure<T>(:final exception) => Result.failure(exception),
    };
  }

  /// Map failure to another exception type
  Result<T> mapException(AppException Function(AppException e) transform) {
    return switch (this) {
      Success<T>(:final data) => Result.success(data),
      Failure<T>(:final exception) => Result.failure(transform(exception)),
    };
  }

  /// Flat map for chaining Result-returning operations
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => transform(data),
      Failure<T>(:final exception) => Result.failure(exception),
    };
  }

  /// Get data or null if failed
  T? getOrNull() {
    return switch (this) {
      Success<T>(:final data) => data,
      Failure<T>() => null,
    };
  }

  /// Get exception or null if successful
  AppException? getExceptionOrNull() {
    return switch (this) {
      Success<T>() => null,
      Failure<T>(:final exception) => exception,
    };
  }

  /// Check if result is success
  bool isSuccess() => this is Success<T>;

  /// Check if result is failure
  bool isFailure() => this is Failure<T>;

  /// Get data or throw exception
  T getOrThrow() {
    return switch (this) {
      Success<T>(:final data) => data,
      Failure<T>(:final exception) => throw exception,
    };
  }

  /// Get data or return default value
  T getOrDefault(T defaultValue) {
    return switch (this) {
      Success<T>(:final data) => data,
      Failure<T>() => defaultValue,
    };
  }

  /// Execute function on both success and failure
  void fold({
    required void Function(T data) onSuccess,
    required void Function(AppException exception) onFailure,
  }) {
    switch (this) {
      case Success<T>(:final data):
        onSuccess(data);
      case Failure<T>(:final exception):
        onFailure(exception);
    }
  }

  /// Convert to string representation for debugging
  @override
  String toString() {
    return switch (this) {
      Success<T>(:final data) => 'Success($data)',
      Failure<T>(:final exception) => 'Failure($exception)',
    };
  }
}

/// Successful result containing data of type T
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Failed result containing an exception
final class Failure<T> extends Result<T> {
  final AppException exception;

  const Failure(this.exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          exception == other.exception;

  @override
  int get hashCode => exception.hashCode;
}
