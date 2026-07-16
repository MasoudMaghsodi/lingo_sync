import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lingo_sync/core/logging/app_logger.dart';
import '../../data/models/daily_task_model.dart';
import '../../data/repositories/daily_task_repository.dart';

part 'daily_tasks_provider.g.dart';

// keepAlive: true — mirrors the original plain `Provider` (not
// `.autoDispose`), so this repository instance is created once and kept
// alive for the app's lifetime instead of being torn down whenever nothing
// happens to be watching it.
@Riverpod(keepAlive: true)
DailyTaskRepository dailyTaskRepository(Ref ref) {
  return DailyTaskRepository(Supabase.instance.client);
}

/// Tasks for a single day of the 50-day plan, keyed by [dayNumber].
///
/// Riverpod generates a family provider automatically because [build] takes
/// an argument — this replaces the old hand-written
/// `StateNotifierProvider.family`, so this module now follows the same
/// `@riverpod` code-gen pattern used across the rest of the app (Auth,
/// Pomodoro, Settings, Dictionary, Mentor).
//
// keepAlive: true — the original StateNotifierProvider.family was a plain
// (non-autoDispose) provider, so each day's fetched task list stayed cached
// for the app's lifetime once loaded. Keeping that same behavior here.
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

    // آپدیت UI بلافاصله (optimistic update)
    state = AsyncValue.data(
      currentTasks
          .map(
            (t) => t.id == task.id
                ? t.copyWith(isCompleted: newCompletionStatus)
                : t,
          )
          .toList(),
    );

    // ۱. آپدیت وضعیت تسک در دیتابیس
    final result = await ref
        .read(dailyTaskRepositoryProvider)
        .toggleTaskCompletion(task.id, newCompletionStatus);

    result.fold(
      onSuccess: (_) async {
        // ۲. اضافه کردن ۱۰ امتیاز به ازای انجام تسک (و کسر در صورت برداشتن تیک)
        try {
          final points = newCompletionStatus ? 10 : -10;
          await Supabase.instance.client.rpc(
            'increment_task_score',
            params: {'points': points},
          );
        } catch (e, st) {
          logger.warning(
            'Failed to update task score after toggling completion',
            context: 'DailyTasks.toggleTask',
            error: e is Exception ? e : Exception(e.toString()),
            stackTrace: st,
            data: {'taskId': task.id, 'points': newCompletionStatus ? 10 : -10},
          );
        }
      },
      onFailure: (exception) {
        // در صورت خطا برگرداندن UI به حالت قبل از تغییر
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
