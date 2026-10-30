import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/result/result.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';
import 'package:lingo_sync/core/utils/streak_calculator.dart';
import 'package:lingo_sync/features/daily_tasks/data/models/leaderboard_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../models/daily_task_model.dart';

class DailyTaskRepository {
  final SupabaseClient _supabase;

  DailyTaskRepository(this._supabase);

  Future<Result<List<DailyTaskModel>>> getTasksForDay(int dayNumber) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result<List<DailyTaskModel>>.failure(
        const AuthException('No authenticated user', code: 'not_authenticated'),
      );
    }

    try {
      final response = await _supabase
          .from('daily_tasks')
          .select('*, user_task_progress(*)')
          .eq('day_number', dayNumber)
          .order('id', ascending: true);

      final tasks = (response as List<dynamic>).map((e) {
        final taskMap = Map<String, dynamic>.from(e as Map<String, dynamic>);
        final progressList = taskMap['user_task_progress'] as List<dynamic>?;
        final isCompleted =
            progressList?.any((p) => p['user_id'] == userId) ?? false;

        taskMap['is_completed'] = isCompleted;
        return DailyTaskModel.fromJson(taskMap);
      }).toList();

      return Result<List<DailyTaskModel>>.success(tasks);
    } catch (e, st) {
      return Result<List<DailyTaskModel>>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'DailyTaskRepository.getTasksForDay',
        ),
      );
    }
  }

  Future<Result<void>> toggleTaskCompletion(
    int taskId,
    bool isCompleted, {
    int? dayNumber,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result<void>.failure(
        const AuthException('No authenticated user', code: 'not_authenticated'),
      );
    }

    try {
      if (isCompleted) {
        await _supabase.from('user_task_progress').upsert({
          'user_id': userId,
          'task_id': taskId,
        });
      } else {
        await _supabase.from('user_task_progress').delete().match({
          'user_id': userId,
          'task_id': taskId,
        });
      }

      // 🚀 همگام‌سازی امتیاز، استریک روزانه و روز جاری در دیتابیس
      final points = isCompleted ? 10 : -10;
      try {
        final stats = await _supabase
            .from('user_stats')
            .select()
            .eq('id', userId)
            .maybeSingle();

        final currentScore = (stats?['score'] as num?)?.toInt() ?? 0;
        final newScore = (currentScore + points).clamp(0, 999999);
        final currentDayInDb = (stats?['current_day'] as num?)?.toInt() ?? 1;
        final newDay = dayNumber != null && dayNumber > currentDayInDb
            ? dayNumber
            : currentDayInDb;

        DateTime? lastActive;
        if (stats?['last_active_date'] != null) {
          lastActive = DateTime.tryParse(stats!['last_active_date'].toString());
        }

        final streakRes = StreakCalculator.evaluate(
          lastActiveDate: lastActive,
          clientDate: DateTime.now(),
          currentStreak: (stats?['streak_days'] as num?)?.toInt() ?? 0,
          availableFreezes:
              (stats?['streak_freeze_count'] as num?)?.toInt() ?? 1,
        );

        await _supabase
            .from('user_stats')
            .update({
              'score': newScore,
              'streak_days': isCompleted
                  ? streakRes.newStreak
                  : ((stats?['streak_days'] as num?)?.toInt() ?? 0),
              'streak_freeze_count': streakRes.remainingFreezes,
              'last_active_date': isCompleted
                  ? streakRes.effectiveDate.toIso8601String()
                  : stats?['last_active_date'],
              'current_day': newDay,
              'last_active': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      } catch (statsErr) {
        // در صورت بروز هرگونه اختلال، از RPC فال‌بک استفاده می‌کنیم
        try {
          await _supabase.rpc(
            'increment_task_score',
            params: {'points': points},
          );
        } catch (_) {}
      }

      return Result<void>.success(null);
    } catch (e, st) {
      return Result<void>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'DailyTaskRepository.toggleTaskCompletion',
        ),
      );
    }
  }

  // ==========================================
  // متدهای مربوط به لیدربورد (انتقال یافته از لایه UI)
  // ==========================================

  /// دریافت آیدی کاربر فعلی برای متمایز کردن او در لیدربورد
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// استریم زنده از لیدربورد
  Stream<List<LeaderboardEntry>> watchLeaderboard() async* {
    // دریافت اطلاعات پروفایل‌ها (نام و عکس)
    final profilesData = await _supabase
        .from('profiles')
        .select('id, full_name, avatar_url');

    final profiles = <String, Map<String, dynamic>>{};
    for (final row in profilesData as List) {
      final id = row['id']?.toString();
      if (id != null) profiles[id] = row as Map<String, dynamic>;
    }

    // استریم تغییرات امتیازات
    yield* _supabase
        .from('user_stats')
        .stream(primaryKey: ['id'])
        // ignore: avoid_redundant_argument_values
        .order('score', ascending: false)
        .map((stats) {
          return stats
              .map(
                (row) => LeaderboardEntry.fromStatsRow(
                  row,
                  profiles[row['id']?.toString()],
                ),
              )
              .toList();
        });
  }
}
