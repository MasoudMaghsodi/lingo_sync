import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingo_sync/core/localization/app_localizations.dart';
import 'package:lingo_sync/core/providers/settings_provider.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/providers/pomodoro_provider.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/widgets/pomodoro_home_card.dart';

// 🚀 کلاس کمکی برای تزریق State تقلبی پومودورو
class MockPomodoroNotifier extends Pomodoro {
  final PomodoroState _mockState;
  MockPomodoroNotifier(this._mockState) : super();

  @override
  PomodoroState build() => _mockState;
}

// 🚀 کلاس کمکی برای تزریق وضعیت زبان تقلبی (همیشه انگلیسی)
class MockIsPersianNotifier extends IsPersian {
  MockIsPersianNotifier() : super();

  @override
  bool build() => false;
}

void main() {
  Widget createWidgetUnderTest(PomodoroState mockState) {
    return ProviderScope(
      overrides: [
        // 🚀 در نسخه‌های جدید Riverpod Generator، سینتکس این‌گونه است: () =>
        pomodoroProvider.overrideWith(() => MockPomodoroNotifier(mockState)),
        isPersianProvider.overrideWith(() => MockIsPersianNotifier()),
      ],
      child: const MaterialApp(home: Scaffold(body: PomodoroHomeCard())),
    );
  }

  group('PomodoroHomeCard Widget Tests', () {
    testWidgets('shows "Start" button when timer is completely idle', (
      tester,
    ) async {
      const idleState = PomodoroState(
        remainingSeconds: 1500,
        isRunning: false,
        defaultMinutes: 25,
        isGloballyVisible: false,
        isFinished: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(idleState));

      // بررسی وجود آیکون تایمر خالی
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      // بررسی وجود دکمه Start
      expect(
        find.text(AppLocalizations.getString('pomodoro_start_button', false)),
        findsOneWidget,
      );
    });

    testWidgets('shows live countdown when timer is running', (tester) async {
      const runningState = PomodoroState(
        remainingSeconds: 1400, // 23:20
        isRunning: true,
        defaultMinutes: 25,
        isGloballyVisible: false,
        isFinished: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(runningState));

      // باید زمان 23:20 را نمایش دهد
      expect(find.text('23:20'), findsOneWidget);
      // آیکون باید پر باشد
      expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
    });
  });
}
