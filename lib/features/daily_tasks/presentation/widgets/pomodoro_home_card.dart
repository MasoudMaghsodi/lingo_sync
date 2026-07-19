import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/constants/app_constants.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import '../../../../core/providers/pomodoro_provider.dart';
import '../../../../core/providers/settings_provider.dart';

/// The Pomodoro timer's permanent home: a static (non-floating) card shown
/// at the top of `DailyTasksPage`.
///
/// - Not visible anywhere (isGloballyVisible == false): shows a
///   "Start"/"Show" button (Start if genuinely idle, Show if it's running
///   in the background but currently hidden).
/// - Visible as the floating overlay elsewhere (isGloballyVisible == true):
///   shows a live compact countdown, purely informational — the floating
///   panel is the primary control surface at that point. This no longer
///   requires isRunning == true, since the overlay legitimately stays up
///   through pause/reset/settings changes too.
class PomodoroHomeCard extends ConsumerWidget {
  const PomodoroHomeCard({super.key});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoro = ref.watch(pomodoroProvider);
    final isPersian = ref.watch(isPersianProvider);
    final theme = Theme.of(context);

    final isFloatingElsewhere = pomodoro.isGloballyVisible;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.standardPadding,
        vertical: AppConstants.smallPadding,
      ),
      padding: const EdgeInsets.all(AppConstants.standardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            pomodoro.isRunning ? Icons.timer_rounded : Icons.timer_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(
              pomodoro.isRunning
                  ? _formatTime(pomodoro.remainingSeconds)
                  : AppLocalizations.getString(
                      'pomodoro_focus_label',
                      isPersian,
                    ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (isFloatingElsewhere)
            Text(
              AppLocalizations.getString('pomodoro_running_label', isPersian),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (!pomodoro.isRunning) {
                  ref.read(pomodoroProvider.notifier).startTimer();
                }
                ref.read(pomodoroProvider.notifier).setVisibility(true);
              },
              child: Text(
                pomodoro.isRunning
                    ? AppLocalizations.getString(
                        'pomodoro_show_button',
                        isPersian,
                      )
                    : AppLocalizations.getString(
                        'pomodoro_start_button',
                        isPersian,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
