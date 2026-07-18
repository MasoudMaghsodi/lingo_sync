import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/result/result.dart';

void main() {
  group('Result', () {
    test('success carries data and reports isSuccess', () {
      final result = Result<int>.success(42);
      expect(result.isSuccess(), isTrue);
      expect(result.isFailure(), isFalse);
      expect(result.getOrNull(), 42);
      expect(result.getExceptionOrNull(), isNull);
    });

    test('failure carries exception and reports isFailure', () {
      const exception = NetworkException('offline');
      final result = Result<int>.failure(exception);
      expect(result.isFailure(), isTrue);
      expect(result.isSuccess(), isFalse);
      expect(result.getOrNull(), isNull);
      expect(result.getExceptionOrNull(), exception);
    });

    test('when() dispatches to the correct branch', () {
      final success = Result<int>.success(1);
      final failure = Result<int>.failure(const UnknownException('boom'));

      expect(
        success.when(success: (d) => 'ok:$d', failure: (e) => 'err'),
        'ok:1',
      );
      expect(
        failure.when(success: (d) => 'ok:$d', failure: (e) => 'err'),
        'err',
      );
    });

    test('map() transforms success but passes through failure', () {
      final success = Result<int>.success(2).map((d) => d * 10);
      expect(success.getOrNull(), 20);

      const exception = TimeoutException('slow');
      final failure = Result<int>.failure(exception).map((d) => d * 10);
      expect(failure.getExceptionOrNull(), exception);
    });

    test('flatMap() chains Result-returning operations', () {
      Result<String> stringify(int n) => Result.success('n=$n');

      final chained = Result<int>.success(5).flatMap(stringify);
      expect(chained.getOrNull(), 'n=5');

      final shortCircuited = Result<int>.failure(
        const StateException('bad'),
      ).flatMap(stringify);
      expect(shortCircuited.isFailure(), isTrue);
    });

    test('mapException() only transforms the failure branch', () {
      final failure = Result<int>.failure(
        const NetworkException('down'),
      ).mapException((e) => const ApiException('wrapped'));
      expect(failure.getExceptionOrNull(), isA<ApiException>());

      final success = Result<int>.success(
        1,
      ).mapException((e) => const ApiException('wrapped'));
      expect(success.getOrNull(), 1);
    });

    test('getOrThrow() returns data or throws the exception', () {
      expect(Result<int>.success(7).getOrThrow(), 7);
      expect(
        () =>
            Result<int>.failure(const ConfigException('missing')).getOrThrow(),
        throwsA(isA<ConfigException>()),
      );
    });

    test('getOrDefault() falls back only on failure', () {
      expect(Result<int>.success(9).getOrDefault(0), 9);
      expect(
        Result<int>.failure(const CacheException('miss')).getOrDefault(0),
        0,
      );
    });

    test('fold() invokes the matching callback with the right value', () {
      var successValue = -1;
      AppException? failureValue;

      Result<int>.success(3).fold(
        onSuccess: (d) => successValue = d,
        onFailure: (e) => failureValue = e,
      );
      expect(successValue, 3);
      expect(failureValue, isNull);

      const exception = PermissionException('denied');
      Result<int>.failure(exception).fold(
        onSuccess: (d) => successValue = d,
        onFailure: (e) => failureValue = e,
      );
      expect(failureValue, exception);
    });
  });
}
