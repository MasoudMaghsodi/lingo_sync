import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/features/daily_tasks/data/models/daily_task_model.dart';

void main() {
  group('DailyTaskModel', () {
    test('fromJson parses all fields correctly', () {
      final task = DailyTaskModel.fromJson({
        'id': 12,
        'day_number': 3,
        'task_type': 'listening',
        'title': 'Listen to podcast',
        'description': 'Episode 4',
        'is_completed': true,
      });

      expect(task.id, 12);
      expect(task.dayNumber, 3);
      expect(task.taskType, 'listening');
      expect(task.title, 'Listen to podcast');
      expect(task.description, 'Episode 4');
      expect(task.isCompleted, isTrue);
    });

    test('fromJson defaults description and isCompleted when missing', () {
      final task = DailyTaskModel.fromJson({
        'id': 1,
        'day_number': 1,
        'task_type': 'reading',
        'title': 'Read article',
      });

      expect(task.description, '');
      expect(task.isCompleted, isFalse);
    });

    test('copyWith only overrides isCompleted, keeps everything else', () {
      final original = DailyTaskModel(
        id: 5,
        dayNumber: 2,
        taskType: 'grammar',
        title: 'Past tense',
        description: 'Irregular verbs',
      );

      final updated = original.copyWith(isCompleted: true);

      expect(updated.isCompleted, isTrue);
      expect(updated.id, original.id);
      expect(updated.dayNumber, original.dayNumber);
      expect(updated.taskType, original.taskType);
      expect(updated.title, original.title);
      expect(updated.description, original.description);
    });
  });
}
