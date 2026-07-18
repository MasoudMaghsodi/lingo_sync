import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/logging/app_logger.dart';

/// Central error handling and recovery service.
///
/// Provides:
/// - Consistent error handling across the app
/// - Automatic retry logic with exponential backoff
/// - User-friendly error messages
/// - Structured error logging
/// - Recovery strategies based on error type
///
/// Usage:
/// ```dart
/// final result = await errorHandler.executeWithRetry(
///   operation: () => repository.fetchData(),
///   retries: 3,
///   context: 'DataFetching',
/// );
/// ```
class ErrorHandlerService {
  /// Maximum retry attempts (can be overridden per operation)
  static const int defaultMaxRetries = 3;

  /// Initial delay between retries in milliseconds
  static const int initialDelayMs = 1000;

  /// Multiplier for exponential backoff (delay multiplied by this each retry)
  static const double backoffMultiplier = 1.5;

  /// Maximum delay between retries in milliseconds
  static const int maxDelayMs = 30000; // 30 seconds

  const ErrorHandlerService();

  /// Execute operation with automatic retry on retryable errors
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required String context,
    int maxRetries = defaultMaxRetries,
    int initialDelayMs = ErrorHandlerService.initialDelayMs,
  }) async {
    int retryCount = 0;
    int delayMs = initialDelayMs;

    while (true) {
      try {
        return await operation();
      } on NetworkException catch (e) {
        if (!e.isRetryable || retryCount >= maxRetries) {
          logger.error(
            'Operation failed (non-retryable)',
            context: context,
            error: e,
            data: {'retryCount': retryCount},
          );
          rethrow;
        }

        retryCount++;
        logger.warning(
          'Network error, retrying... (attempt $retryCount/$maxRetries)',
          context: context,
          error: e,
          data: {'delayMs': delayMs},
        );

        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs = (delayMs * backoffMultiplier).toInt();
        if (delayMs > maxDelayMs) delayMs = maxDelayMs;
      } catch (e) {
        logger.error(
          'Unexpected error in operation',
          context: context,
          error: e is Exception ? e : Exception(e.toString()),
          data: {'retryCount': retryCount},
        );
        rethrow;
      }
    }
  }

  /// Convert any exception to AppException
  AppException toAppException(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    if (error is AppException) return error;

    final String message = error is Exception
        ? error.toString()
        : 'خطای نامشخص: ${error.toString()}';

    if (error is Exception) {
      logger.warning(
        'Converting exception to AppException',
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return UnknownException(
      message,
      originalException: error,
      stackTrace: stackTrace,
    );
  }

  /// Get user-friendly error message based on exception type
  String getUserMessage(AppException exception) {
    return switch (exception) {
      AuthException() =>
        'خطا در احراز هویت. لطفاً دوباره تلاش کنید یا رمز خود را تغییر دهید.',
      NetworkException() => 'خطای اتصال. اتصال اینترنت خود را بررسی کنید.',
      ValidationException() =>
        'داده‌های وارد شده نامعتبر هستند. لطفاً بررسی کنید.',
      DatabaseException() => 'خطا در پایگاه داده. لطفاً دوباره تلاش کنید.',
      CacheException() =>
        'خطا در دسترسی به حافظه موقت. لطفاً برنامه را دوباره راه‌اندازی کنید.',
      FileException() => 'خطا در دسترسی به فایل. لطفاً دوباره تلاش کنید.',
      PermissionException() => 'شما اجازه دسترسی به این منبع را ندارید.',
      ApiException() => 'خطا در سرویس. لطفاً بعداً تلاش کنید.',
      StateException() =>
        'برنامه در حالت نامعتبری قرار دارد. لطفاً برنامه را دوباره راه‌اندازی کنید.',
      ConfigException() =>
        'خطا در پیکربندی برنامه. لطفاً تماس بگیرید پشتیبانی.',
      WebSocketException() =>
        'ارتباط قطع شد. لطفاً اتصال اینترنت را بررسی کنید.',
      TimeoutException() =>
        'زمان انتظار تمام شد. لطفاً اتصال بررسی کنید و دوباره تلاش کنید.',
      UnknownException() => 'خطای نامشخص. لطفاً بعداً تلاش کنید.',
    };
  }

  /// Get developer-friendly error message
  String getDeveloperMessage(AppException exception) {
    final buffer = StringBuffer()
      ..writeln(exception.runtimeType)
      ..writeln('Message: ${exception.message}');

    if (exception case final AuthException e) {
      buffer.writeln('Code: ${e.code}');
    } else if (exception case final NetworkException e) {
      buffer.writeln('Status Code: ${e.statusCode}');
      buffer.writeln('Retryable: ${e.isRetryable}');
    } else if (exception case final ValidationException e) {
      buffer.writeln('Field: ${e.fieldName}');
      buffer.writeln('Rule: ${e.validationRule}');
    } else if (exception case final DatabaseException e) {
      buffer.writeln('Operation: ${e.operation}');
      buffer.writeln('Table: ${e.tableName}');
    }

    return buffer.toString();
  }

  /// Log exception with full context
  void logException(
    AppException exception, {
    required String context,
    Map<String, dynamic>? additionalData,
  }) {
    final Map<String, dynamic> data = additionalData ?? {};
    data['exceptionType'] = exception.runtimeType.toString();

    if (exception case final NetworkException e) {
      data['statusCode'] = e.statusCode;
      data['retryable'] = e.isRetryable;
    }

    logger.error(
      exception.message,
      context: context,
      error: exception,
      stackTrace: exception.stackTrace,
      data: data,
    );
  }

  /// Check if exception is retryable
  bool isRetryable(AppException exception) {
    return exception is NetworkException && exception.isRetryable;
  }

  /// Check if exception is user-facing (should show to user)
  bool isUserFacing(AppException exception) {
    return exception is! StateException && exception is! ConfigException;
  }
}

/// Global error handler instance
const errorHandler = ErrorHandlerService();
