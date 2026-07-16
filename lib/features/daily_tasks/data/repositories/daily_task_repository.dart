import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/logging/app_logger.dart';
import 'package:lingo_sync/core/result/result.dart';
import '../models/daily_task_model.dart';

/// Owns reading the 50-day task plan and toggling a user's completion of a
/// task. Returns [Result] instead of throwing or using the previous
/// `Either<String, T>` pattern, so callers get a typed [AppException] on
/// failure instead of a raw, hardcoded-language error string — see
/// [AppException] / `ErrorHandlerService` for how the UI turns that into a
/// user-facing message.
class DailyTaskRepository {
  final SupabaseClient _supabase;

  DailyTaskRepository(this._supabase);

  /// Fetches every task for [dayNumber], along with whether the current
  /// user has already completed each one.
  Future<Result<List<DailyTaskModel>>> getTasksForDay(int dayNumber) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result<List<DailyTaskModel>>.failure(
        const AuthException('No authenticated user', code: 'not_authenticated'),
      );
    }

    try {
      // دریافت تسک‌ها به همراه رکوردهای انجام شده از جدول واسط
      final response = await _supabase
          .from('daily_tasks')
          .select('*, user_task_progress(*)')
          .eq('day_number', dayNumber)
          .order('id', ascending: true);

      final tasks = (response as List<dynamic>).map((e) {
        final taskMap = Map<String, dynamic>.from(e as Map<String, dynamic>);

        // استخراج جدول واسط برای این تسک
        final progressList = taskMap['user_task_progress'] as List<dynamic>?;

        // بررسی اینکه آیا آیدی کاربر فعلی در بین کسانی که این تسک را انجام
        // داده‌اند هست یا خیر
        final isCompleted =
            progressList?.any((p) => p['user_id'] == userId) ?? false;

        // تزریق فیلد به Map تا مُدل (Model) بدون هیچ تغییری کار کند
        taskMap['is_completed'] = isCompleted;

        return DailyTaskModel.fromJson(taskMap);
      }).toList();

      return Result<List<DailyTaskModel>>.success(tasks);
    } catch (e, st) {
      logger.error(
        'Failed to load tasks for day $dayNumber',
        context: 'DailyTaskRepository.getTasksForDay',
        error: e is Exception ? e : Exception(e.toString()),
        stackTrace: st,
      );
      return Result<List<DailyTaskModel>>.failure(
        DatabaseException(
          'Failed to fetch daily tasks',
          operation: 'select',
          tableName: 'daily_tasks',
          stackTrace: st,
        ),
      );
    }
  }

  /// Marks [taskId] as completed or not for the current user.
  Future<Result<void>> toggleTaskCompletion(
    int taskId,
    bool isCompleted,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result<void>.failure(
        const AuthException('No authenticated user', code: 'not_authenticated'),
      );
    }

    try {
      if (isCompleted) {
        // ایجاد رکورد جدید در جدول واسط (Upsert برای جلوگیری از ارور دوتایی شدن)
        await _supabase.from('user_task_progress').upsert({
          'user_id': userId,
          'task_id': taskId,
        });
      } else {
        // حذف تیک (حذف رکورد از جدول واسط)
        await _supabase.from('user_task_progress').delete().match({
          'user_id': userId,
          'task_id': taskId,
        });
      }
      return Result<void>.success(null);
    } catch (e, st) {
      logger.error(
        'Failed to toggle completion for task $taskId',
        context: 'DailyTaskRepository.toggleTaskCompletion',
        error: e is Exception ? e : Exception(e.toString()),
        stackTrace: st,
      );
      return Result<void>.failure(
        DatabaseException(
          'Failed to update task completion',
          operation: isCompleted ? 'upsert' : 'delete',
          tableName: 'user_task_progress',
          stackTrace: st,
        ),
      );
    }
  }
}
