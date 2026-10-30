import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/constants/app_constants.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import 'package:lingo_sync/core/providers/app_shell_provider.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';

import '../../../../core/layout/main_navigation.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../ai_dictionary/presentation/providers/dictionary_provider.dart';
import '../../data/models/daily_task_model.dart';
import '../providers/daily_tasks_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/selected_day_provider.dart';

class DailyTasksPage extends ConsumerStatefulWidget {
  const DailyTasksPage({super.key});

  @override
  ConsumerState<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends ConsumerState<DailyTasksPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedDay = ref.read(selectedDayProvider);
      _scrollToDay(selectedDay);
    });
  }

  void _scrollToDay(int day) {
    if (_scrollController.hasClients) {
      final position = (day - 1) * 72.0;
      _scrollController.animateTo(
        position,
        duration: UIConstants.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getIconForTaskType(String type) {
    switch (type.toLowerCase()) {
      case 'listening':
        return Icons.headphones_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'speaking':
        return Icons.mic_rounded;
      case 'writing':
        return Icons.edit_document;
      case 'grammar':
        return Icons.rule_rounded;
      case 'vocabulary':
        return Icons.style_rounded;
      case 'review':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  Color _getColorForTaskType(String type, ThemeData theme) {
    switch (type.toLowerCase()) {
      case 'speaking':
        return Colors.tealAccent.shade700;
      case 'listening':
        return Colors.blueAccent;
      case 'vocabulary':
        return Colors.deepPurpleAccent;
      case 'grammar':
        return Colors.indigoAccent;
      case 'writing':
        return Colors.orangeAccent.shade700;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final tasksState = ref.watch(dailyTasksProvider(selectedDay));
    final isPersian = ref.watch(isPersianProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () =>
              ref.read(appShellScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPersian ? 'برنامه‌ریز ۴۹ روزه' : '49-Day Roadmap',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                isPersian ? 'روز $selectedDay' : 'Day $selectedDay',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // دکمه پومودورو در نوار بالا
          Consumer(
            builder: (context, ref, _) {
              final pomodoro = ref.watch(pomodoroProvider);
              final isRunning = pomodoro.isRunning;
              final seconds = pomodoro.remainingSeconds;
              final m = (seconds ~/ 60).toString().padLeft(2, '0');
              final s = (seconds % 60).toString().padLeft(2, '0');

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(pomodoroProvider.notifier).toggleVisibility();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isRunning
                          ? Colors.amber.withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRunning
                            ? Colors.amber
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.15,
                              ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRunning
                              ? Icons.hourglass_top_rounded
                              : Icons.timer_outlined,
                          size: 14,
                          color: isRunning
                              ? Colors.amber
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                        if (isRunning) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$m:$s',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ۱. تایم‌لاین افقی روزهای ۱ تا ۴۹
          Container(
            height: 48,
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 49,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = day == selectedDay;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedDayProvider.notifier).setDay(day);
                    _scrollToDay(day);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark ? const Color(0xFF151926) : Colors.white),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.12,
                              ),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        isPersian ? 'روز $day' : 'Day $day',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ۲. خلاصه وضعیت روز جاری
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: tasksState.maybeWhen(
              data: (tasks) {
                final total = tasks.length;
                final done = tasks.where((t) => t.isCompleted).length;
                final progress = total > 0 ? (done / total) : 0.0;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF151926) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPersian
                                ? 'پیشرفت برنامه روز $selectedDay'
                                : 'Day $selectedDay Progress',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '$done از $total تسک',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),

          // ۳. لیست تسک‌های روز جاری
          Expanded(
            child: tasksState.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(UIConstants.largePadding),
                  child: Text(
                    error is AppException
                        ? errorHandler.getUserMessage(error)
                        : AppLocalizations.getString(
                            'tasks_loading_error',
                            isPersian,
                          ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 72,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.25,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isPersian
                              ? 'هیچ تسکی برای روز $selectedDay ثبت نشده است.'
                              : 'No tasks scheduled for Day $selectedDay.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 100, // فضای خالی برای نوار شناور پایین
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final taskColor = _getColorForTaskType(
                      task.taskType,
                      theme,
                    );

                    return _buildTaskCard(
                      task: task,
                      taskColor: taskColor,
                      selectedDay: selectedDay,
                      theme: theme,
                      isDark: isDark,
                      isPersian: isPersian,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required DailyTaskModel task,
    required Color taskColor,
    required int selectedDay,
    required ThemeData theme,
    required bool isDark,
    required bool isPersian,
  }) {
    final hasVideo = task.videoUrl != null && task.videoUrl!.isNotEmpty;

    return AnimatedContainer(
      duration: UIConstants.animationDuration,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? (isDark
                  ? const Color(0xFF11141F)
                  : Colors.green.shade50.withValues(alpha: 0.4))
            : (isDark ? const Color(0xFF151926) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: task.isCompleted
              ? Colors.green.withValues(alpha: 0.4)
              : theme.colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(dailyTasksProvider(selectedDay).notifier).toggleTask(task);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // آیکون نوع تسک
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: taskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getIconForTaskType(task.taskType),
                    color: taskColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // اطلاعات تسک
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? theme.colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      )
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+10 XP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (hasVideo) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            // Analyze video in Dictionary tab
                            ref
                                .read(videoProcessingProvider.notifier)
                                .analyzeYoutubeVideo(task.videoUrl!);
                            ref
                                .read(mainNavigationTabProvider.notifier)
                                .setTab(4); // Dictionary Tab
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 14,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPersian
                                      ? 'مشاهده ویدیو و لغات'
                                      : 'Watch Video & Vocabulary',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // چک‌باکس تیک
                AnimatedContainer(
                  duration: UIConstants.animationDuration,
                  curve: Curves.easeInOutBack,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted
                          ? Colors.green
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
