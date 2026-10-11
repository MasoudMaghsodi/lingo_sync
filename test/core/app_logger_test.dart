import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/core/logging/app_logger.dart';
import 'package:lingo_sync/core/logging/log_level.dart';

void main() {
  late AppLogger appLogger;

  setUp(() {
    appLogger = AppLogger(
      minimumLevel: LogLevel.debug,
      enableConsoleOutput: false, // در تست خروجی کنسول نمی‌خواهیم
    );
  });

  group('AppLogger — history management', () {
    test('logs are stored in history in order', () {
      appLogger.info('first');
      appLogger.info('second');
      appLogger.info('third');

      final history = appLogger.getHistory();
      expect(history.length, 3);
      expect(history[0].message, 'first');
      expect(history[2].message, 'third');
    });

    test('clearHistory removes all entries', () {
      appLogger.info('entry');
      appLogger.clearHistory();
      expect(appLogger.getHistory(), isEmpty);
    });

    test('getLogsByLevel filters correctly', () {
      appLogger.debug('d');
      appLogger.warning('w');
      appLogger.error('e');

      final warnings = appLogger.getLogsByLevel(LogLevel.warning);
      expect(warnings.length, 1);
      expect(warnings.first.message, 'w');
    });

    test('getLogsByContext filters correctly', () {
      appLogger.info('msg1', context: 'AuthRepo');
      appLogger.info('msg2', context: 'WordRepo');
      appLogger.info('msg3', context: 'AuthRepo');

      final authLogs = appLogger.getLogsByContext('AuthRepo');
      expect(authLogs.length, 2);
      expect(authLogs.every((e) => e.context == 'AuthRepo'), isTrue);
    });

    test('logs below minimumLevel are not stored', () {
      final warnOnlyLogger = AppLogger(
        minimumLevel: LogLevel.warning,
        enableConsoleOutput: false,
      );

      warnOnlyLogger.debug('invisible debug');
      warnOnlyLogger.info('invisible info');
      warnOnlyLogger.warning('visible');

      expect(warnOnlyLogger.getHistory().length, 1);
      expect(warnOnlyLogger.getHistory().first.message, 'visible');
    });

    test('history is capped at maxHistorySize', () {
      for (int i = 0; i < AppLogger.maxHistorySize + 10; i++) {
        appLogger.info('msg $i');
      }
      expect(appLogger.getHistory().length, AppLogger.maxHistorySize);
    });

    test('exportAsJson returns list of maps', () {
      appLogger.info('export me', context: 'TestCtx');
      final json = appLogger.exportAsJson();
      expect(json, isA<List<Map<String, dynamic>>>());
      expect(json.first['message'], 'export me');
    });

    test('exportAsText returns non-empty string', () {
      appLogger.error('something bad');
      final text = appLogger.exportAsText();
      expect(text, contains('something bad'));
    });
  });

  group('AppLogger — log level ordering', () {
    test('LogLevel.shouldLog respects hierarchy', () {
      expect(LogLevel.debug.shouldLog(LogLevel.debug), isTrue);
      expect(LogLevel.info.shouldLog(LogLevel.debug), isTrue);
      expect(LogLevel.warning.shouldLog(LogLevel.info), isTrue);
      expect(LogLevel.debug.shouldLog(LogLevel.warning), isFalse);
      expect(LogLevel.info.shouldLog(LogLevel.error), isFalse);
    });
  });
}
