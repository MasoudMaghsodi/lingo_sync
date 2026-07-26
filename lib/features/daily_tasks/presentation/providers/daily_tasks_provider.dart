import 'package:lingo_sync/core/logging/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/daily_task_model.dart';
import '../../data/repositories/daily_task_repository.dart';

part 'daily_tasks_provider.g.dart';

@Riverpod(keepAlive: true)
DailyTaskRepository dailyTaskRepository(Ref ref) {
  return DailyTaskRepository(Supabase.instance.client);
}

@Riverpod(keepAlive: true)
class DailyTasks extends _$DailyTasks {
  @override
  Future<List<DailyTaskModel>> build(int dayNumber) async {
    final result = await ref
        .watch(dailyTaskRepositoryProvider)
        .getTasksForDay(dayNumber);
    return result.getOrThrow();
  }

  Future<void> toggleTask(DailyTaskModel task) async {
    final currentTasks = state.value ?? [];
    final newCompletionStatus = !task.isCompleted;

    // آپدیت UI بلافاصله (Optimistic Update)
    state = AsyncValue.data(
      currentTasks
          .map(
            (t) => t.id == task.id
                ? t.copyWith(isCompleted: newCompletionStatus)
                : t,
          )
          .toList(),
    );

    // 🚀 واگذاری تمام عملیات (تیک زدن و آپدیت امتیاز) به گارسون
    final result = await ref
        .read(dailyTaskRepositoryProvider)
        .toggleTaskCompletion(task.id, newCompletionStatus);

    result.fold(
      onSuccess: (_) {
        // هیچ کار اضافه‌ای نیاز نیست، دیتابیس با موفقیت آپدیت شد
      },
      onFailure: (exception) {
        // در صورت خطا برگرداندن UI به حالت قبل
        state = AsyncValue.data(currentTasks);
        logger.warning(
          'Failed to toggle task completion, reverted optimistic update',
          context: 'DailyTasks.toggleTask',
          error: exception,
          data: {'taskId': task.id},
        );
      },
    );
  }
}
