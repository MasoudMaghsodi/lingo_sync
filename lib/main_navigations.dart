import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
import 'package:lingo_sync/core/providers/pomodoro_provider.dart';
import 'package:lingo_sync/core/providers/settings_provider.dart';
import 'package:lingo_sync/features/ai_dictionary/presentation/pages/dictionary_page.dart';
import 'package:lingo_sync/features/ai_dictionary/presentation/pages/flashcards_page.dart';
import 'package:lingo_sync/features/ai_mentor/presentation/widgets/ai_mentor_sheet.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/pages/daily_tasks_page.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/pages/leaderboard_page.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/widgets/floating_pomodoro.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});
  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  // Which tabs have ever been shown. A tab's real page widget is only
  // constructed the first time its index becomes active — before that we
  // render an empty placeholder instead. See the fuller explanation on
  // this in the previous refactor phase's commit notes: it avoids
  // subscribing to stream-backed providers (like the leaderboard) before
  // the widget tree has even finished its first build.
  final Set<int> _builtIndices = {0};

  static final List<Widget Function()> _pageBuilders = [
    () => const DailyTasksPage(),
    () => const DictionaryPage(),
    () => const SizedBox.shrink(), // فضای خالی برای دکمه شناور وسط
    () => const FlashcardsPage(),
    () => const LeaderboardPage(),
  ];

  void _selectTab(int index) {
    if (index == 2) {
      return; // جلوگیری از کرش وقتی روی فضای خالی وسط کلیک می‌شود
    }
    setState(() {
      _currentIndex = index;
      _builtIndices.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPersian = ref.watch(isPersianProvider);
    final theme = Theme.of(context);

    // The floating Pomodoro overlay only exists while the timer is
    // actually running AND the user hasn't hidden it — otherwise its
    // permanent home is the PomodoroHomeCard on the Daily Tasks page. This
    // is what stops it "wandering" across every tab when idle.
    final pomodoro = ref.watch(pomodoroProvider);
    final showFloatingPomodoro =
        pomodoro.isRunning && pomodoro.isGloballyVisible;

    return Scaffold(
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

      // =====================================
      // دکمه جادویی احضار استاد (AI Mentor)
      // =====================================
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AiMentorSheet(),
          );
        },
        child: Container(
          width: 65,
          height: 65,
          margin: const EdgeInsets.only(top: 30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, Colors.deepPurpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.check_box_outlined),
            label: AppLocalizations.getString('nav_tasks', isPersian),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: AppLocalizations.getString('nav_dictionary', isPersian),
          ),
          const NavigationDestination(icon: SizedBox.shrink(), label: ''),
          NavigationDestination(
            icon: const Icon(Icons.style_outlined),
            label: AppLocalizations.getString('nav_review', isPersian),
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            label: AppLocalizations.getString('nav_leaderboard', isPersian),
          ),
        ],
      ),
    );
  }
}
