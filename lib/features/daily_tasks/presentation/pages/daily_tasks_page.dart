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
import '../../../error_genome/presentation/widgets/active_error_genome_section.dart';
import '../providers/daily_tasks_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/selected_day_provider.dart';
import '../widgets/daily_sync_mission_card.dart';

class DailyTasksPage extends ConsumerStatefulWidget {
  const DailyTasksPage({super.key});

  @override
  ConsumerState<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends ConsumerState<DailyTasksPage> {
  final ScrollController _scrollController = ScrollController();
  int _homeSegmentIndex = 0; // 0: Tasks, 1: Error Genome

  @override
  void initState() {
    super.initState();

    // اسکرول خودکار به روز انتخاب شده
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedDay = ref.read(selectedDayProvider);
      _scrollToDay(selectedDay);
    });
  }

  void _scrollToDay(int day) {
    if (_scrollController.hasClients) {
      final position = (day - 1) * 65.0; // عرض تقریبی هر آیتم
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

  Widget _buildHomeSegmentButton({
    required int index,
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _homeSegmentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _homeSegmentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.16)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.grey.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final tasksState = ref.watch(dailyTasksProvider(selectedDay));
    final isPersian = ref.watch(isPersianProvider);
    final theme = Theme.of(context);

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
              AppLocalizations.getString('tasks_title', isPersian),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                isPersian ? 'روز $selectedDay از ۵۰' : 'Day $selectedDay/50',
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
          // دکمه دسترسی سریع به تایمر پومودورو بدون شلوغ کردن صفحه
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
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isRunning
                          ? Colors.amber.withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRunning ? Colors.amber : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRunning
                              ? Icons.timer_rounded
                              : Icons.timer_outlined,
                          size: 16,
                          color: isRunning ? Colors.amber : Colors.grey,
                        ),
                        if (isRunning) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$m:$s',
                            style: const TextStyle(
                              fontSize: 11.5,
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
        children: [
          // ۱. هدر باریک و مدرن روزها (Timeline)
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 4),
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
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.18),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
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
                          fontSize: 12,
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

          // ۲. ماموریت روزانه ۱۰ دقیقه‌ای (هیرو کارت سه‌بعدی)
          DailySyncMissionCard(
            completedMissionsCount: tasksState.maybeWhen(
              data: (tasks) =>
                  tasks.where((t) => t.isCompleted).length.clamp(0, 3),
              orElse: () => 0,
            ),
            onOpenVideo: () {
              ref.read(mainNavigationTabProvider.notifier).setTab(1);
            },
            onOpenFlashcards: () {
              ref.read(mainNavigationTabProvider.notifier).setTab(3);
            },
          ),

          // ۳. سوییچر دسته‌بندی برای رفع شلوغی صفحه
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _buildHomeSegmentButton(
                    index: 0,
                    icon: Icons.checklist_rounded,
                    label: isPersian ? 'تسک‌های تمرینی' : 'Daily Tasks',
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildHomeSegmentButton(
                    index: 1,
                    icon: Icons.biotech_rounded,
                    label: isPersian ? 'ژنوم خطاهای من' : 'Error Genome',
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),

          // ۴. محتوای تب انتخاب‌شده (یا لیست تسک‌ها یا ژنوم خطا)
          Expanded(
            child: _homeSegmentIndex == 1
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ActiveErrorGenomeSection(isPersian: isPersian),
                  )
                : tasksState.when(
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
                                Icons.weekend_rounded,
                                size: 80,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.getString(
                                  'no_tasks',
                                  isPersian,
                                ),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return AnimatedContainer(
                            duration: UIConstants.animationDuration,
                            margin: const EdgeInsets.only(
                              bottom: UIConstants.standardPadding,
                            ),
                            decoration: BoxDecoration(
                              color: task.isCompleted
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.05,
                                    )
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(
                                UIConstants.largeBorderRadius,
                              ),
                              border: Border.all(
                                color: task.isCompleted
                                    ? Colors.green.withValues(alpha: 0.5)
                                    : Colors.grey.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  UIConstants.largeBorderRadius,
                                ),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(
                                        dailyTasksProvider(
                                          selectedDay,
                                        ).notifier,
                                      )
                                      .toggleTask(task);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    UIConstants.standardPadding,
                                  ),
                                  child: Row(
                                    children: [
                                      // آیکون نوع تسک
                                      Container(
                                        padding: const EdgeInsets.all(
                                          UIConstants.smallPadding + 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getIconForTaskType(task.taskType),
                                          color: theme.colorScheme.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: UIConstants.standardPadding,
                                      ),

                                      // اطلاعات تسک
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                decoration: task.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                color: task.isCompleted
                                                    ? Colors.grey
                                                    : theme
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              task.description,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // دکمه تیک با انیمیشن
                                      AnimatedContainer(
                                        duration: UIConstants.animationDuration,
                                        curve: Curves.easeInOutBack,
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: task.isCompleted
                                              ? Colors.green
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: task.isCompleted
                                                ? Colors.green
                                                : Colors.grey.shade400,
                                            width: 2,
                                          ),
                                        ),
                                        child: task.isCompleted
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
}
