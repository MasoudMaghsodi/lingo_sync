import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/localization/app_localizations.dart';
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
  // render an empty placeholder instead.
  //
  // This matters because every tab lives inside an IndexedStack, and
  // IndexedStack builds ALL of its children up front (even the ones not
  // currently visible) so their state survives switching tabs. Without
  // this guard, a tab like LeaderboardPage — which subscribes to a
  // Supabase realtime stream the moment it's built — starts that
  // subscription immediately on app launch, before the widget tree has
  // even finished its first build. If the stream's first value arrives in
  // that same window, Riverpod ends up trying to schedule a rebuild while
  // Flutter is still mid-build, throwing
  // "setState() or markNeedsBuild() called during build."
  //
  // Building each tab lazily — only once the user actually switches to it
  // — sidesteps that race entirely, and as a bonus means tabs the user
  // never visits never even subscribe to their providers.
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
