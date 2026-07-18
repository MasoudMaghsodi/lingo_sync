import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:lingo_sync/core/constants/app_constants.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/daily_tasks_provider.dart';
import '../providers/selected_day_provider.dart';

class DailyTasksPage extends ConsumerStatefulWidget {
  const DailyTasksPage({super.key});

  @override
  ConsumerState<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends ConsumerState<DailyTasksPage> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });

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
        duration: AppConstants.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
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

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final tasksState = ref.watch(dailyTasksProvider(selectedDay));
    final isPersian = ref.watch(isPersianProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              AppLocalizations.getString('tasks_title', isPersian),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              DateFormat('yyyy/MM/dd - HH:mm').format(_now),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // هدر روزها (Timeline)
          Container(
            height: 75,
            margin: const EdgeInsets.symmetric(
              vertical: AppConstants.smallPadding,
            ),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 49,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.standardPadding,
              ),
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
                    duration: const Duration(milliseconds: 250),
                    width: isSelected ? 65 : 55,
                    margin: EdgeInsets.only(
                      left: isPersian ? AppConstants.smallPadding : 0,
                      right: isPersian ? 0 : AppConstants.smallPadding,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(
                        AppConstants.largeBorderRadius,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.getString('day', isPersian),
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // لیست تسک‌ها با انیمیشن
          Expanded(
            child: tasksState.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
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
                          AppLocalizations.getString('no_tasks', isPersian),
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
                    vertical: AppConstants.standardPadding,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return AnimatedContainer(
                      duration: AppConstants.animationDuration,
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.standardPadding,
                      ),
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? theme.colorScheme.primary.withValues(alpha: 0.05)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppConstants.largeBorderRadius,
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
                            AppConstants.largeBorderRadius,
                          ),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(dailyTasksProvider(selectedDay).notifier)
                                .toggleTask(task);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppConstants.standardPadding,
                            ),
                            child: Row(
                              children: [
                                // آیکون نوع تسک
                                Container(
                                  padding: const EdgeInsets.all(
                                    AppConstants.smallPadding + 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIconForTaskType(task.taskType),
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(
                                  width: AppConstants.standardPadding,
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
                                              : theme.colorScheme.onSurface,
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
                                  duration: AppConstants.animationDuration,
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
