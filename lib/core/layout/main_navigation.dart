import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/features/ai_dictionary/presentation/pages/dictionary_page.dart';
import 'package:lingo_sync/features/ai_dictionary/presentation/pages/flashcards_page.dart';
import 'package:lingo_sync/features/ai_mentor/presentation/widgets/ai_mentor_sheet.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/pages/daily_tasks_page.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/pages/leaderboard_page.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/providers/pomodoro_provider.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/widgets/floating_pomodoro.dart';
import 'package:lingo_sync/features/settings/presentation/widgets/app_drawer.dart';

import '../../core/providers/app_shell_provider.dart';
import '../../core/providers/settings_provider.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});
  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  final Set<int> _builtIndices = {0};

  static final List<Widget Function()> _pageBuilders = [
    () => const DailyTasksPage(),
    () => const DictionaryPage(),
    () => const SizedBox.shrink(), // فضای خالی وسط
    () => const FlashcardsPage(),
    () => const LeaderboardPage(),
  ];

  void _selectTab(int index) {
    if (index == 2) return;
    setState(() {
      _currentIndex = index;
      _builtIndices.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = ref.watch(appShellScaffoldKeyProvider);
    final pomodoro = ref.watch(pomodoroProvider);
    final showFloatingPomodoro = pomodoro.isGloballyVisible;

    return Scaffold(
      key: scaffoldKey,
      extendBody: true, // اجازه می‌دهد محتوای صفحه زیر نویگیشن بار شناور برود
      drawer: const AppSettingsDrawer(),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: List.generate(
              _pageBuilders.length,
              (index) => _builtIndices.contains(index)
                  ? _pageBuilders[index]()
                  : const SizedBox.shrink(),
            ),
          ),
          if (showFloatingPomodoro) const FloatingPomodoro(),
        ],
      ),
      // استفاده از Stack برای قرار دادن داک شناور در پایین صفحه
      bottomNavigationBar: _buildFloating3DNavBar(context),
    );
  }

  Widget _buildFloating3DNavBar(BuildContext context) {
    final theme = Theme.of(context);
    final isPersian = ref.watch(isPersianProvider);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        height: 75,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            // سایه تیره برای ایجاد ارتفاع
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            // سایه روشن (Highlight) برای ایجاد حس لبه‌های ۳ بعدی
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              0,
              Icons.check_box_outlined,
              Icons.check_box,
              'nav_tasks',
              isPersian,
            ),
            _buildNavItem(
              1,
              Icons.search_outlined,
              Icons.saved_search,
              'nav_dictionary',
              isPersian,
            ),

            // دکمه برجسته و ۳ بعدی AI Mentor در مرکز
            _buildAiMentorButton(theme),

            _buildNavItem(
              3,
              Icons.style_outlined,
              Icons.style,
              'nav_review',
              isPersian,
            ),
            _buildNavItem(
              4,
              Icons.leaderboard_outlined,
              Icons.leaderboard,
              'nav_leaderboard',
              isPersian,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String labelKey,
    bool isPersian,
  ) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _selectTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? solidIcon : outlineIcon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 26,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAiMentorButton(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AiMentorSheet(),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        transform: Matrix4.translationValues(
          0,
          -15,
          0,
        ), // هدایت به سمت بالا برای خروج از داک
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              const Color(0xFF8E24AA),
            ], // طلایی به بنفش پررنگ
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: 3,
              offset: const Offset(0, 8), // سایه بلند برای حس معلق بودن
            ),
            // رفلکس داخلی برای حس شیشه‌ای/برجسته بودن
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.graphic_eq_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
