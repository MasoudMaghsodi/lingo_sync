import 'dart:async';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'settings_provider.dart';

part 'pomodoro_provider.g.dart';

// SharedPreferences keys used to persist a running session across app kill.
const _kPrefMinutes = 'pomodoro_time';
const _kPrefEndEpochMs = 'pomodoro_end_epoch_ms';
const _kPrefWasRunning = 'pomodoro_was_running';

class PomodoroState {
  final int remainingSeconds;
  final bool isRunning;
  final int defaultMinutes;
  final bool isGloballyVisible;
  final bool isFinished;

  const PomodoroState({
    required this.remainingSeconds,
    required this.isRunning,
    required this.defaultMinutes,
    required this.isGloballyVisible,
    required this.isFinished,
  });

  PomodoroState copyWith({
    int? remainingSeconds,
    bool? isRunning,
    int? defaultMinutes,
    bool? isGloballyVisible,
    bool? isFinished,
  }) {
    return PomodoroState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      defaultMinutes: defaultMinutes ?? this.defaultMinutes,
      isGloballyVisible: isGloballyVisible ?? this.isGloballyVisible,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

// keepAlive: true — without it, this notifier auto-disposes (and its Timer
// gets cancelled) the moment no widget happens to be watching it, e.g. while
// the user is on the login / awaiting-approval screen. That silently wipes
// a running session for no good reason.
@Riverpod(keepAlive: true)
class Pomodoro extends _$Pomodoro {
  Timer? _timer;

  // The actual wall-clock moment the current session should end. Ticking
  // against this (instead of just doing `remainingSeconds - 1` every tick)
  // means the countdown can never drift: even if the OS suspends the app's
  // Dart timers for a while (backgrounded, screen locked, etc.), the moment
  // they resume we recompute from the real target time and land on the
  // correct remaining value instead of "pausing" during that gap.
  DateTime? _endTime;

  @override
  PomodoroState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedMinutes = prefs.getInt(_kPrefMinutes) ?? 25;

    ref.onDispose(() {
      _timer?.cancel();
    });

    // Try to recover a session that was running when the app was last closed.
    final wasRunning = prefs.getBool(_kPrefWasRunning) ?? false;
    final savedEndEpochMs = prefs.getInt(_kPrefEndEpochMs);

    if (wasRunning && savedEndEpochMs != null) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(savedEndEpochMs);
      final diff = endTime.difference(DateTime.now()).inSeconds;

      if (diff > 0) {
        // Session was still running when the app died — resume it exactly
        // where it should be, and restart the ticker. Genuinely in
        // progress, so it's correct for this to be globally visible right
        // away.
        _endTime = endTime;
        _scheduleTicker();
        return PomodoroState(
          remainingSeconds: diff,
          isRunning: true,
          defaultMinutes: savedMinutes,
          isGloballyVisible: true,
          isFinished: false,
        );
      } else {
        // Session finished while the app was closed — surface it as
        // finished once (so the user sees "Done!"), then clear the
        // persisted session.
        _clearPersistedSession(prefs);
        return PomodoroState(
          remainingSeconds: savedMinutes * 60,
          isRunning: false,
          defaultMinutes: savedMinutes,
          isGloballyVisible: true,
          isFinished: true,
        );
      }
    }

    // Genuinely fresh state — nothing running, nothing to resume, nothing
    // finished. isGloballyVisible starts false here so the floating
    // overlay doesn't appear anywhere until the user explicitly starts (or
    // reopens) the timer via PomodoroHomeCard. Previously this defaulted
    // to true, which is what made the timer "wander" onto every page even
    // when it had never been started.
    return PomodoroState(
      remainingSeconds: savedMinutes * 60,
      isRunning: false,
      defaultMinutes: savedMinutes,
      isGloballyVisible: false,
      isFinished: false,
    );
  }

  void _clearPersistedSession(dynamic prefs) {
    prefs.remove(_kPrefEndEpochMs);
    prefs.setBool(_kPrefWasRunning, false);
  }

  void _scheduleTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final endTime = _endTime;
    if (endTime == null) {
      _timer?.cancel();
      return;
    }

    final diff = endTime.difference(DateTime.now()).inSeconds;

    if (diff > 0) {
      // Only touch state when the value actually changed, to avoid
      // redundant rebuilds if a tick fires slightly early.
      if (diff != state.remainingSeconds) {
        state = state.copyWith(remainingSeconds: diff);
      }
      return;
    }

    // Finished.
    _timer?.cancel();
    _endTime = null;
    _clearPersistedSession(ref.read(sharedPreferencesProvider));
    HapticFeedback.heavyImpact();
    state = state.copyWith(
      isRunning: false,
      isFinished: true,
      remainingSeconds: state.defaultMinutes * 60,
    );
  }

  void toggleTimer() {
    if (state.isRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  void startTimer() {
    if (state.isRunning) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final seconds = state.remainingSeconds > 0
        ? state.remainingSeconds
        : state.defaultMinutes * 60;

    _endTime = DateTime.now().add(Duration(seconds: seconds));
    prefs.setInt(_kPrefEndEpochMs, _endTime!.millisecondsSinceEpoch);
    prefs.setBool(_kPrefWasRunning, true);

    state = state.copyWith(
      isRunning: true,
      isFinished: false,
      isGloballyVisible: true,
      remainingSeconds: seconds,
    );

    _scheduleTicker();
  }

  void pauseTimer() {
    _timer?.cancel();

    // Recompute the exact remaining time from the wall-clock target rather
    // than trusting whatever the last per-second tick happened to store —
    // this avoids an off-by-one-second pause.
    final endTime = _endTime;
    final remaining = endTime != null
        ? endTime.difference(DateTime.now()).inSeconds.clamp(0, 1 << 30)
        : state.remainingSeconds;

    _endTime = null;
    _clearPersistedSession(ref.read(sharedPreferencesProvider));

    state = state.copyWith(isRunning: false, remainingSeconds: remaining);
  }

  void setVisibility(bool visible) {
    state = state.copyWith(isGloballyVisible: visible);
  }

  void resetTimer() {
    _timer?.cancel();
    _endTime = null;
    _clearPersistedSession(ref.read(sharedPreferencesProvider));
    state = state.copyWith(
      isRunning: false,
      isFinished: false,
      remainingSeconds: state.defaultMinutes * 60,
    );
  }

  void setCustomTime(int minutes) {
    _timer?.cancel();
    _endTime = null;

    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt(_kPrefMinutes, minutes);
    _clearPersistedSession(prefs);

    state = state.copyWith(
      defaultMinutes: minutes,
      remainingSeconds: minutes * 60,
      isRunning: false,
      isFinished: false,
    );
  }
}
