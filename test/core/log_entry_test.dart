import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/logging/log_entry.dart';
import 'package:lingo_sync/core/logging/log_level.dart';

void main() {
  group('LogEntry.toJson', () {
    test('includes required fields', () {
      final entry = LogEntry(level: LogLevel.info, message: 'test message');
      final json = entry.toJson();
      expect(json['level'], 'INFO');
      expect(json['message'], 'test message');
      expect(json['timestamp'], isNotNull);
    });

    test('includes optional context when present', () {
      final entry = LogEntry(
        level: LogLevel.error,
        message: 'error',
        context: 'AuthRepo',
      );
      expect(entry.toJson()['context'], 'AuthRepo');
    });

    test('omits optional fields when null', () {
      final entry = LogEntry(level: LogLevel.debug, message: 'debug');
      final json = entry.toJson();
      expect(json.containsKey('context'), isFalse);
      expect(json.containsKey('error'), isFalse);
    });

    test('includes error string when present', () {
      final entry = LogEntry(
        level: LogLevel.error,
        message: 'failed',
        error: const NetworkException('no connection'),
      );
      expect(entry.toJson()['error'], contains('NetworkException'));
    });

    test('includes data map when present', () {
      final entry = LogEntry(
        level: LogLevel.info,
        message: 'with data',
        data: {'userId': '123', 'count': 5},
      );
      final json = entry.toJson();
      expect(json['data'], isA<Map>());
      expect(json['data']['userId'], '123');
    });
  });

  group('LogEntry.toConsoleString', () {
    test('contains log level label', () {
      final entry = LogEntry(level: LogLevel.warning, message: 'warn msg');
      expect(entry.toConsoleString(), contains('WARNING'));
    });

    test('contains the message', () {
      final entry = LogEntry(level: LogLevel.info, message: 'hello world');
      expect(entry.toConsoleString(), contains('hello world'));
    });

    test('contains context in brackets when set', () {
      final entry = LogEntry(
        level: LogLevel.info,
        message: 'msg',
        context: 'WordRepo',
      );
      expect(entry.toConsoleString(), contains('[WordRepo]'));
    });
  });
}
