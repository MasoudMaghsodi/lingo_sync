import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';

void main() {
  const handler = ErrorHandlerService();

  group('ErrorHandlerService.getUserMessage', () {
    test('returns auth message for AuthException', () {
      const e = AuthException('bad');
      final msg = handler.getUserMessage(e);
      expect(msg, isNotEmpty);
      expect(msg, contains('احراز هویت'));
    });

    test('returns network message for NetworkException', () {
      const e = NetworkException('no conn');
      expect(handler.getUserMessage(e), contains('اتصال'));
    });

    test('returns permission message for PermissionException', () {
      const e = PermissionException('denied');
      expect(handler.getUserMessage(e), contains('اجازه'));
    });

    test('returns timeout message for TimeoutException', () {
      const e = TimeoutException('slow');
      expect(handler.getUserMessage(e), contains('انتظار'));
    });
  });

  group('ErrorHandlerService.isRetryable', () {
    test('NetworkException with isRetryable=true is retryable', () {
      const e = NetworkException('flaky');
      expect(handler.isRetryable(e), isTrue);
    });

    test('NetworkException with isRetryable=false is NOT retryable', () {
      const e = NetworkException('permanent', isRetryable: false);
      expect(handler.isRetryable(e), isFalse);
    });

    test('non-network exceptions are not retryable', () {
      const e = AuthException('bad token');
      expect(handler.isRetryable(e), isFalse);
    });
  });

  group('ErrorHandlerService.isUserFacing', () {
    test('StateException is not user-facing', () {
      const e = StateException('bad state');
      expect(handler.isUserFacing(e), isFalse);
    });

    test('ConfigException is not user-facing', () {
      const e = ConfigException('missing key');
      expect(handler.isUserFacing(e), isFalse);
    });

    test('NetworkException is user-facing', () {
      const e = NetworkException('no connection');
      expect(handler.isUserFacing(e), isTrue);
    });

    test('AuthException is user-facing', () {
      const e = AuthException('invalid credentials');
      expect(handler.isUserFacing(e), isTrue);
    });
  });

  group('ErrorHandlerService.toAppException', () {
    test('returns AppException as-is when already one', () {
      const e = CacheException('miss');
      final result = handler.toAppException(e, null);
      expect(result, same(e));
    });

    test('wraps unknown exceptions in UnknownException', () {
      final result = handler.toAppException(Exception('raw'), null);
      expect(result, isA<UnknownException>());
      expect(result.message, isNotEmpty);
    });
  });

  group('ErrorHandlerService.executeWithRetry', () {
    test('returns result immediately on success', () async {
      var callCount = 0;
      final result = await handler.executeWithRetry<int>(
        operation: () async {
          callCount++;
          return 42;
        },
        context: 'test',
      );
      expect(result, 42);
      expect(callCount, 1);
    });

    test(
      'retries on retryable NetworkException and eventually succeeds',
      () async {
        var callCount = 0;
        final result = await handler.executeWithRetry<String>(
          operation: () async {
            callCount++;
            if (callCount < 3) {
              throw const NetworkException('flaky');
            }
            return 'ok';
          },
          context: 'test',
          initialDelayMs: 1, // بدون delay در تست
        );
        expect(result, 'ok');
        expect(callCount, 3);
      },
    );

    test('does NOT retry on non-retryable NetworkException', () async {
      var callCount = 0;
      expect(
        () => handler.executeWithRetry<void>(
          operation: () async {
            callCount++;
            throw const NetworkException('permanent', isRetryable: false);
          },
          context: 'test',
          initialDelayMs: 1,
        ),
        throwsA(isA<NetworkException>()),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(callCount, 1);
    });
  });
}
