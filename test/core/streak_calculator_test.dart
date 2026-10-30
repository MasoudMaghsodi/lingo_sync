import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/core/utils/streak_calculator.dart';

void main() {
  group('StreakCalculator.evaluate', () {
    final today = DateTime(2026, 10, 30);
    final yesterday = DateTime(2026, 10, 29);
    final twoDaysAgo = DateTime(2026, 10, 28);
    final fourDaysAgo = DateTime(2026, 10, 26);

    test('first time active returns streak 1', () {
      final res = StreakCalculator.evaluate(
        lastActiveDate: null,
        clientDate: today,
        currentStreak: 0,
        availableFreezes: 1,
      );

      expect(res.newStreak, 1);
      expect(res.remainingFreezes, 1);
      expect(res.freezeUsed, false);
      expect(res.isStreakBroken, false);
    });

    test('same day active keeps streak unchanged', () {
      final res = StreakCalculator.evaluate(
        lastActiveDate: today,
        clientDate: today,
        currentStreak: 5,
        availableFreezes: 1,
      );

      expect(res.newStreak, 5);
      expect(res.remainingFreezes, 1);
      expect(res.freezeUsed, false);
      expect(res.isStreakBroken, false);
    });

    test('consecutive day increments streak', () {
      final res = StreakCalculator.evaluate(
        lastActiveDate: yesterday,
        clientDate: today,
        currentStreak: 5,
        availableFreezes: 1,
      );

      expect(res.newStreak, 6);
      expect(res.remainingFreezes, 1);
      expect(res.freezeUsed, false);
      expect(res.isStreakBroken, false);
    });

    test(
      'vacation mode preserves and increments streak without using freeze',
      () {
        final res = StreakCalculator.evaluate(
          lastActiveDate: fourDaysAgo,
          clientDate: today,
          currentStreak: 10,
          availableFreezes: 1,
          isVacationMode: true,
          vacationUntil: DateTime(2026, 11, 5),
        );

        expect(res.newStreak, 11);
        expect(res.remainingFreezes, 1);
        expect(res.freezeUsed, false);
        expect(res.isStreakBroken, false);
      },
    );

    test(
      'missed 1 day with available freeze consumes freeze and continues streak',
      () {
        final res = StreakCalculator.evaluate(
          lastActiveDate: twoDaysAgo,
          clientDate: today,
          currentStreak: 7,
          availableFreezes: 2,
        );

        expect(res.newStreak, 8);
        expect(res.remainingFreezes, 1);
        expect(res.freezeUsed, true);
        expect(res.isStreakBroken, false);
      },
    );

    test('missed 1 day with 0 freezes breaks streak and resets to 1', () {
      final res = StreakCalculator.evaluate(
        lastActiveDate: twoDaysAgo,
        clientDate: today,
        currentStreak: 7,
        availableFreezes: 0,
      );

      expect(res.newStreak, 1);
      expect(res.remainingFreezes, 0);
      expect(res.freezeUsed, false);
      expect(res.isStreakBroken, true);
    });

    test('missed multiple days breaks streak and resets to 1', () {
      final res = StreakCalculator.evaluate(
        lastActiveDate: fourDaysAgo,
        clientDate: today,
        currentStreak: 12,
        availableFreezes: 1,
      );

      expect(res.newStreak, 1);
      expect(res.remainingFreezes, 1);
      expect(res.freezeUsed, false);
      expect(res.isStreakBroken, true);
    });
  });

  group('StreakCalculator.calculateXp', () {
    test(
      'computes base tasks, flashcards, voice minutes, and bonus correctly',
      () {
        final xp = StreakCalculator.calculateXp(
          baseTasksCompleted: 3, // 3 * 20 = 60
          flashcardsReviewed: 5, // 5 * 10 = 50
          voiceMinutesUsed: 4, // 4 * 15 = 60
          completedDailySync: true, // +50
        );

        expect(xp, 60 + 50 + 60 + 50); // 220 XP
      },
    );

    test('computes without bonus when daily sync not completed', () {
      final xp = StreakCalculator.calculateXp(
        baseTasksCompleted: 1, // 20
        flashcardsReviewed: 2, // 20
      );

      expect(xp, 40);
    });
  });
}
