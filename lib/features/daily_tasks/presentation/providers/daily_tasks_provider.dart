import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/daily_task_repository.dart';
import '../../data/models/daily_task_model.dart';

final dailyTaskRepositoryProvider = Provider<DailyTaskRepository>((ref) {
  return DailyTaskRepository(Supabase.instance.client);
});

final dailyTasksProvider =
    StateNotifierProvider.family<
      DailyTasksNotifier,
      AsyncValue<List<DailyTaskModel>>,
      int
    >((ref, dayNumber) {
      return DailyTasksNotifier(
        ref.read(dailyTaskRepositoryProvider),
        dayNumber,
      );
    });

class DailyTasksNotifier
    extends StateNotifier<AsyncValue<List<DailyTaskModel>>> {
  final DailyTaskRepository _repository;
  final int _dayNumber;

  DailyTasksNotifier(this._repository, this._dayNumber)
    : super(const AsyncValue.loading()) {
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    state = const AsyncValue.loading();
    final result = await _repository.getTasksForDay(_dayNumber);

    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (tasks) => state = AsyncValue.data(tasks),
    );
  }

  Future<void> toggleTask(DailyTaskModel task) async {
    final currentTasks = state.value ?? [];
    final newCompletionStatus = !task.isCompleted;

    // آپدیت UI بلافاصله
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
    final result = await _repository.toggleTaskCompletion(
      task.id,
      newCompletionStatus,
    );

    result.fold(
      (error) {
        state = AsyncValue.data(currentTasks); // در صورت خطا برگرداندن UI
      },
      (_) async {
        // ۲. اضافه کردن ۱۰ امتیاز به ازای انجام تسک (و کسر در صورت برداشتن تیک)
        try {
          final points = newCompletionStatus ? 10 : -10;
          await Supabase.instance.client.rpc(
            'increment_task_score',
            params: {'points': points},
          );
        } catch (e) {
          // خطا در ثبت امتیاز
        }
      },
    );
  }
}
