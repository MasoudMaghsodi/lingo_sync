import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/core/providers/pomodoro_provider.dart';

void main() {
  group('PomodoroState', () {
    test('constructor holds every field exactly as given', () {
      const state = PomodoroState(
        remainingSeconds: 1500,
        isRunning: false,
        defaultMinutes: 25,
        isGloballyVisible: true,
        isFinished: false,
      );

      expect(state.remainingSeconds, 1500);
      expect(state.isRunning, isFalse);
      expect(state.defaultMinutes, 25);
      expect(state.isGloballyVisible, isTrue);
      expect(state.isFinished, isFalse);
    });

    test('copyWith overrides only the given fields', () {
      const original = PomodoroState(
        remainingSeconds: 1500,
        isRunning: false,
        defaultMinutes: 25,
        isGloballyVisible: true,
        isFinished: false,
      );

      final updated = original.copyWith(
        isRunning: true,
        remainingSeconds: 1499,
      );

      expect(updated.isRunning, isTrue);
      expect(updated.remainingSeconds, 1499);
      // Untouched fields carry over unchanged.
      expect(updated.defaultMinutes, 25);
      expect(updated.isGloballyVisible, isTrue);
      expect(updated.isFinished, isFalse);
    });

    test('copyWith with no arguments returns an equivalent state', () {
      const original = PomodoroState(
        remainingSeconds: 600,
        isRunning: true,
        defaultMinutes: 10,
        isGloballyVisible: false,
        isFinished: false,
      );

      final copy = original.copyWith();

      expect(copy.remainingSeconds, original.remainingSeconds);
      expect(copy.isRunning, original.isRunning);
      expect(copy.defaultMinutes, original.defaultMinutes);
      expect(copy.isGloballyVisible, original.isGloballyVisible);
      expect(copy.isFinished, original.isFinished);
    });
  });
}
