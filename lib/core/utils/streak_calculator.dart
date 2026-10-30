/// Pure evaluation result for a streak calculation
class StreakEvaluationResult {
  final int newStreak;
  final int remainingFreezes;
  final bool freezeUsed;
  final bool isStreakBroken;
  final DateTime effectiveDate;

  const StreakEvaluationResult({
    required this.newStreak,
    required this.remainingFreezes,
    required this.freezeUsed,
    required this.isStreakBroken,
    required this.effectiveDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakEvaluationResult &&
          runtimeType == other.runtimeType &&
          newStreak == other.newStreak &&
          remainingFreezes == other.remainingFreezes &&
          freezeUsed == other.freezeUsed &&
          isStreakBroken == other.isStreakBroken &&
          effectiveDate.year == other.effectiveDate.year &&
          effectiveDate.month == other.effectiveDate.month &&
          effectiveDate.day == other.effectiveDate.day;

  @override
  int get hashCode => Object.hash(
    newStreak,
    remainingFreezes,
    freezeUsed,
    isStreakBroken,
    effectiveDate.year,
    effectiveDate.month,
    effectiveDate.day,
  );
}

/// Pure functions for streak calculation, grace freezes, and competence XP
class StreakCalculator {
  /// Normalizes a DateTime to midnight (date only)
  static DateTime normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Evaluates user streak continuity given client date and user state.
  static StreakEvaluationResult evaluate({
    required DateTime? lastActiveDate,
    required DateTime clientDate,
    required int currentStreak,
    required int availableFreezes,
    bool isVacationMode = false,
    DateTime? vacationUntil,
  }) {
    final normalizedClientDate = normalizeDate(clientDate);

    // 1. First time ever
    if (lastActiveDate == null) {
      return StreakEvaluationResult(
        newStreak: 1,
        remainingFreezes: availableFreezes,
        freezeUsed: false,
        isStreakBroken: false,
        effectiveDate: normalizedClientDate,
      );
    }

    final normalizedLastDate = normalizeDate(lastActiveDate);
    final daysDifference = normalizedClientDate
        .difference(normalizedLastDate)
        .inDays;

    // 2. Already active on the same calendar day
    if (daysDifference <= 0) {
      return StreakEvaluationResult(
        newStreak: currentStreak > 0 ? currentStreak : 1,
        remainingFreezes: availableFreezes,
        freezeUsed: false,
        isStreakBroken: false,
        effectiveDate: normalizedLastDate,
      );
    }

    // 3. Consecutive day (yesterday)
    if (daysDifference == 1) {
      return StreakEvaluationResult(
        newStreak: currentStreak + 1,
        remainingFreezes: availableFreezes,
        freezeUsed: false,
        isStreakBroken: false,
        effectiveDate: normalizedClientDate,
      );
    }

    // 4. Vacation mode active and within allowed period
    if (isVacationMode) {
      final isWithinVacation =
          vacationUntil == null ||
          !normalizedClientDate.isAfter(normalizeDate(vacationUntil));
      if (isWithinVacation) {
        return StreakEvaluationResult(
          newStreak: currentStreak + 1,
          remainingFreezes: availableFreezes,
          freezeUsed: false,
          isStreakBroken: false,
          effectiveDate: normalizedClientDate,
        );
      }
    }

    // 5. Missed exactly 1 day (daysDifference == 2) and freeze available
    if (daysDifference == 2 && availableFreezes > 0) {
      return StreakEvaluationResult(
        newStreak: currentStreak + 1,
        remainingFreezes: availableFreezes - 1,
        freezeUsed: true,
        isStreakBroken: false,
        effectiveDate: normalizedClientDate,
      );
    }

    // 6. Streak broken
    return StreakEvaluationResult(
      newStreak: 1,
      remainingFreezes: availableFreezes,
      freezeUsed: false,
      isStreakBroken: true,
      effectiveDate: normalizedClientDate,
    );
  }

  /// Calculates Competence XP
  static int calculateXp({
    required int baseTasksCompleted,
    int flashcardsReviewed = 0,
    int voiceMinutesUsed = 0,
    bool completedDailySync = false,
  }) {
    int total = baseTasksCompleted * 20;
    total += flashcardsReviewed * 10;
    total += voiceMinutesUsed * 15;
    if (completedDailySync) total += 50; // Daily Sync Bonus
    return total;
  }
}
