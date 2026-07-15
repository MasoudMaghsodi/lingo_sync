import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final List<Widget> _pages = const [
    DailyTasksPage(),
    DictionaryPage(),
    SizedBox.shrink(), // فضای خالی برای دکمه شناور وسط
    FlashcardsPage(),
    LeaderboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isPersian = ref.watch(isPersianProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          const FloatingPomodoro(),
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
        onDestinationSelected: (index) {
          if (index == 2) {
            return; // جلوگیری از کرش وقتی روی فضای خالی وسط کلیک می‌شود
          }
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.check_box_outlined),
            label: isPersian ? 'تسک‌ها' : 'Tasks',
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: isPersian ? 'دیکشنری' : 'Dictionary',
          ),
          const NavigationDestination(icon: SizedBox.shrink(), label: ''),
          NavigationDestination(
            icon: const Icon(Icons.style_outlined),
            label: isPersian ? 'مرور' : 'Review',
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            label: isPersian ? 'رتبه‌بندی' : 'Leaderboard',
          ),
        ],
      ),
    );
  }
}
