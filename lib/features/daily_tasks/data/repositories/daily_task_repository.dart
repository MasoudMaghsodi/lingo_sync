import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_task_model.dart';

class DailyTaskRepository {
  final SupabaseClient _supabase;

  DailyTaskRepository(this._supabase);

  // دریافت تسک‌های یک روز مشخص (با بررسی پیشرفت کاربر فعلی)
  Future<Either<String, List<DailyTaskModel>>> getTasksForDay(
    int dayNumber,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return const Left('کاربر لاگین نیست');

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

        // بررسی اینکه آیا آیدی کاربر فعلی در بین کسانی که این تسک را انجام داده‌اند هست یا خیر
        final isCompleted =
            progressList?.any((p) => p['user_id'] == userId) ?? false;

        // تزریق فیلد به Map تا مُدل (Model) بدون هیچ تغییری کار کند
        taskMap['is_completed'] = isCompleted;

        return DailyTaskModel.fromJson(taskMap);
      }).toList();

      return Right(tasks);
    } catch (e) {
      return Left('خطا در دریافت اطلاعات: $e');
    }
  }

  // آپدیت وضعیت انجام تسک
  Future<Either<String, void>> toggleTaskCompletion(
    int taskId,
    bool isCompleted,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return const Left('کاربر لاگین نیست');

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
      return const Right(null);
    } catch (e) {
      return Left('خطا در بروزرسانی تسک: $e');
    }
  }
}
