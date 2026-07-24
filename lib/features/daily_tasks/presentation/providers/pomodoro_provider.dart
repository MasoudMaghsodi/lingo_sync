import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/settings_provider.dart';

part 'pomodoro_provider.g.dart';

// کلیدهای ذخیره‌سازی محلی (فقط مختص همین فیچر)
const _kPrefMinutes = 'pomodoro_time';
const _kPrefEndEpochMs = 'pomodoro_end_epoch_ms';
const _kPrefWasRunning = 'pomodoro_was_running';

/// مدل وضعیت پومودورو - کاملا Immutable (غیرقابل تغییر)
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

@Riverpod(keepAlive: true)
class Pomodoro extends _$Pomodoro {
  Timer? _timer;
  DateTime? _endTime;

  @override
  PomodoroState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedMinutes = prefs.getInt(_kPrefMinutes) ?? 25;

    // پاکسازی امن تایمر هنگام از بین رفتن پرووایدر
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    final wasRunning = prefs.getBool(_kPrefWasRunning) ?? false;
    final savedEndEpochMs = prefs.getInt(_kPrefEndEpochMs);

    // بازیابی سشن قبلی در صورت بسته شدن ناگهانی اپلیکیشن
    if (wasRunning && savedEndEpochMs != null) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(savedEndEpochMs);
      final diff = endTime.difference(DateTime.now()).inSeconds;

      if (diff > 0) {
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
        _clearPersistedSession();
        return PomodoroState(
          remainingSeconds: savedMinutes * 60,
          isRunning: false,
          defaultMinutes: savedMinutes,
          isGloballyVisible: true,
          isFinished: true,
        );
      }
    }

    // وضعیت کاملا جدید
    return PomodoroState(
      remainingSeconds: savedMinutes * 60,
      isRunning: false,
      defaultMinutes: savedMinutes,
      isGloballyVisible: false,
      isFinished: false,
    );
  }

  void _clearPersistedSession() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove(_kPrefEndEpochMs);
    prefs.setBool(_kPrefWasRunning, false);
  }

  void _scheduleTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_endTime == null) {
      _timer?.cancel();
      return;
    }

    final diff = _endTime!.difference(DateTime.now()).inSeconds;

    if (diff > 0) {
      if (diff != state.remainingSeconds) {
        state = state.copyWith(remainingSeconds: diff);
      }
      return;
    }

    // پایان زمان تمرکز
    _timer?.cancel();
    _endTime = null;
    _clearPersistedSession();

    state = state.copyWith(
      isRunning: false,
      isFinished: true,
      remainingSeconds: state.defaultMinutes * 60,
    );

    // نکته منتورینگ: ویبره (HapticFeedback) رو از اینجا حذف کردم.
    // ویبره باید در لایه UI وقتی `isFinished` برابر true شد فراخوانی بشه.
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

    final remaining = _endTime != null
        ? _endTime!.difference(DateTime.now()).inSeconds.clamp(0, 1 << 30)
        : state.remainingSeconds;

    _endTime = null;
    _clearPersistedSession();

    state = state.copyWith(isRunning: false, remainingSeconds: remaining);
  }

  void setVisibility(bool visible) {
    if (state.isGloballyVisible != visible) {
      state = state.copyWith(isGloballyVisible: visible);
    }
  }

  void resetTimer() {
    _timer?.cancel();
    _endTime = null;
    _clearPersistedSession();
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
    _clearPersistedSession();

    state = state.copyWith(
      defaultMinutes: minutes,
      remainingSeconds: minutes * 60,
      isRunning: false,
      isFinished: false,
    );
  }
}
