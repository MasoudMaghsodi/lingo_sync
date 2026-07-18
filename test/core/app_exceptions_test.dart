import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';

void main() {
  group('AppException subtypes', () {
    test('NetworkException.toString includes status code when present', () {
      const withStatus = NetworkException('timed out', statusCode: 504);
      const withoutStatus = NetworkException('no connection');

      expect(withStatus.toString(), 'NetworkException(504): timed out');
      expect(withoutStatus.toString(), 'NetworkException: no connection');
    });

    test('ApiException.toString includes status code when present', () {
      const exception = ApiException('bad word', statusCode: 400);
      expect(exception.toString(), 'ApiException(400): bad word');
    });

    test('AuthException.toString includes code when present', () {
      const withCode = AuthException('bad login', code: 'invalid_credentials');
      const withoutCode = AuthException('unknown auth error');

      expect(
        withCode.toString(),
        'AuthException(invalid_credentials): bad login',
      );
      expect(withoutCode.toString(), 'AuthException: unknown auth error');
    });

    test('NetworkException defaults to retryable', () {
      const exception = NetworkException('flaky connection');
      expect(exception.isRetryable, isTrue);
    });

    test('every subtype is an AppException', () {
      const exceptions = <AppException>[
        AuthException('a'),
        NetworkException('b'),
        ValidationException('c'),
        DatabaseException('d'),
        CacheException('e'),
        FileException('f'),
        PermissionException('g'),
        ApiException('h'),
        StateException('i'),
        ConfigException('j'),
        WebSocketException('k'),
        TimeoutException('l'),
        UnknownException('m'),
      ];

      for (final exception in exceptions) {
        expect(exception, isA<AppException>());
        expect(exception.message, isNotEmpty);
      }
    });
  });
}
