import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lingo_sync/core/sync/outbox_sync_service.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box {}

void main() {
  group('OutboxSyncService Tests', () {
    late MockBox mockBox;
    late OutboxSyncService syncService;
    final Map<dynamic, dynamic> inMemoryStorage = {};

    setUp(() {
      inMemoryStorage.clear();
      mockBox = MockBox();

      when(() => mockBox.get(any())).thenAnswer((inv) {
        final key = inv.positionalArguments[0];
        return inMemoryStorage[key];
      });

      when(() => mockBox.put(any(), any())).thenAnswer((inv) {
        final key = inv.positionalArguments[0];
        final val = inv.positionalArguments[1];
        inMemoryStorage[key] = val;
        return Future.value();
      });

      when(() => mockBox.delete(any())).thenAnswer((inv) {
        final key = inv.positionalArguments[0];
        inMemoryStorage.remove(key);
        return Future.value();
      });

      syncService = OutboxSyncService(mockBox);
    });

    test('enqueue creates and persists an OutboxItem with UUID', () async {
      expect(syncService.pendingCount, equals(0));

      final id = await syncService.enqueue(
        actionType: 'srs_review',
        payload: {
          'flashcard_id': 123,
          'quality': 5,
        },
      );

      expect(id.isNotEmpty, isTrue);
      expect(syncService.pendingCount, equals(1));

      final items = syncService.getPendingItems();
      expect(items.length, equals(1));
      expect(items.first.id, equals(id));
      expect(items.first.actionType, equals('srs_review'));
      expect(items.first.payload['flashcard_id'], equals(123));
      expect(items.first.payload['quality'], equals(5));
    });

    test('enqueue multiple items appends them in order', () async {
      await syncService.enqueue(
        actionType: 'srs_review',
        payload: {'flashcard_id': 1},
      );
      await syncService.enqueue(
        actionType: 'task_completion',
        payload: {'task_id': 42},
      );

      expect(syncService.pendingCount, equals(2));
      final items = syncService.getPendingItems();
      expect(items[0].actionType, equals('srs_review'));
      expect(items[1].actionType, equals('task_completion'));
    });

    test('clear removes all pending items', () async {
      await syncService.enqueue(
        actionType: 'srs_review',
        payload: {'flashcard_id': 1},
      );
      expect(syncService.pendingCount, equals(1));

      await syncService.clear();
      expect(syncService.pendingCount, equals(0));
    });
  });
}
