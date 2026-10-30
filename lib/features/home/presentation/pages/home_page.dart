import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/layout/main_navigation.dart';
import 'package:lingo_sync/core/providers/app_mode_provider.dart';
import 'package:lingo_sync/core/providers/app_shell_provider.dart';
import 'package:lingo_sync/core/providers/settings_provider.dart';
import 'package:lingo_sync/core/widgets/three_dimensional_parallax_card.dart';
import 'package:lingo_sync/features/ai_dictionary/presentation/providers/flashcards_provider.dart';
import 'package:lingo_sync/features/ai_mentor/presentation/widgets/ai_mentor_sheet.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/providers/daily_tasks_provider.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/providers/pomodoro_provider.dart';
import 'package:lingo_sync/features/daily_tasks/presentation/providers/selected_day_provider.dart';
import 'package:lingo_sync/features/error_genome/presentation/widgets/active_error_genome_section.dart';
import 'package:lingo_sync/features/exam_twin/presentation/widgets/exam_twin_sheet.dart';
import 'package:lingo_sync/features/home/presentation/pages/general_hub_page.dart';
import 'package:lingo_sync/features/practice/presentation/widgets/c1_upgrade_studio_sheet.dart';
import 'package:lingo_sync/features/settings/presentation/providers/profile_provider.dart';
import 'package:lingo_sync/features/subscription/presentation/widgets/subscription_checkout_sheet.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _getGreeting(bool isPersian) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return isPersian ? 'صبح بخیر ☀️' : 'Good Morning ☀️';
    } else if (hour >= 12 && hour < 17) {
      return isPersian ? 'ظهر بخیر 🌤️' : 'Good Afternoon 🌤️';
    } else if (hour >= 17 && hour < 21) {
      return isPersian ? 'عصر بخیر 🌅' : 'Good Evening 🌅';
    } else {
      return isPersian ? 'شب بخیر 🌙' : 'Good Night 🌙';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPersian = ref.watch(isPersianProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final currentDay = ref.watch(selectedDayProvider);
    final tasksAsync = ref.watch(dailyTasksProvider(currentDay));
    final flashcardsAsync = ref.watch(flashcardsProvider);
    final pomodoro = ref.watch(pomodoroProvider);

    final profile = profileAsync.asData?.value;
    final name = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!
        : (isPersian ? 'زبان‌آموز کوشا' : 'Learner');
    final level = profile?.englishLevel ?? 'B2';
    final score = profile?.score ?? 0;
    final streak = profile?.streakDays ?? 1;

    final dueCount = flashcardsAsync.asData?.value.length ?? 0;
    final tasks = tasksAsync.asData?.value ?? [];
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'LingoSync',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Pomodoro Live Pill
          Consumer(
            builder: (context, ref, _) {
              final isRunning = pomodoro.isRunning;
              final seconds = pomodoro.remainingSeconds;
              final m = (seconds ~/ 60).toString().padLeft(2, '0');
              final s = (seconds % 60).toString().padLeft(2, '0');

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
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
                          ? Colors.amber.withValues(alpha: 0.18)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRunning
                            ? Colors.amber
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.12,
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
                        const SizedBox(width: 5),
                        Text(
                          '$m:$s',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isRunning
                                ? Colors.amber
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Subscription PRO Badge
          IconButton(
            tooltip: isPersian ? 'مدیریت اشتراک' : 'Subscription',
            icon: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              SubscriptionCheckoutSheet.show(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyTasksProvider(currentDay));
          ref.invalidate(flashcardsProvider);
        },
        child: Column(
          children: [
            // 0. Dual-Mode Segmented Switcher (عمومی vs پرو VIP)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildModeSwitcher(
                currentMode: ref.watch(appHubModeProvider),
                isPersian: isPersian,
                isDark: isDark,
                theme: theme,
                onModeSelected: (mode) {
                  HapticFeedback.selectionClick();
                  ref.read(appHubModeProvider.notifier).setMode(mode);
                },
              ),
            ),

            // Mode Content
            Expanded(
              child: ref.watch(appHubModeProvider) == AppHubMode.general
                  ? const GeneralHubPage()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 4,
                        bottom: 100, // Space for floating dock
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. User Header & Stats Bar
                          _buildHeaderSection(
                            name: name,
                            greeting: _getGreeting(isPersian),
                            streak: streak,
                            score: score,
                            level: level,
                            theme: theme,
                            isDark: isDark,
                            isPersian: isPersian,
                            onLeaderboardTap: () {
                              HapticFeedback.lightImpact();
                              // Switch to Leaderboard or open Leaderboard
                              ref
                                  .read(mainNavigationTabProvider.notifier)
                                  .setTab(4);
                            },
                          ),

                          const SizedBox(height: 18),

                          // 2. Hero Spotlight 3D Card: "Daily Sync Mission"
                          _buildDailyMissionHeroCard(
                            day: currentDay,
                            completedCount: completedCount,
                            totalCount: totalCount,
                            progress: progress,
                            theme: theme,
                            isDark: isDark,
                            isPersian: isPersian,
                            onStartMission: () {
                              HapticFeedback.mediumImpact();
                              // Jump to Tab 1 (Planner)
                              ref
                                  .read(mainNavigationTabProvider.notifier)
                                  .setTab(1);
                            },
                          ),

                          const SizedBox(height: 20),

                          // 3. Section Title: دسترسی سریع ۳ بعدی
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isPersian
                                    ? 'مراکز تمرین و ابزارها'
                                    : 'Practice Hubs',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                isPersian ? 'هوش مصنوعی زنده' : 'AI Powered',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 4. Quick Action 3D Cards Grid
                          _buildLiveVoiceMentorCard(
                            theme: theme,
                            isDark: isDark,
                            isPersian: isPersian,
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const AiMentorSheet(),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              // Flashcards Due Card
                              Expanded(
                                child: _buildSmallHubCard(
                                  title: isPersian
                                      ? 'جعبه لایتنر'
                                      : 'Leitner Deck',
                                  subtitle: isPersian
                                      ? '$dueCount کارت آماده'
                                      : '$dueCount Due Cards',
                                  badge: 'SRS',
                                  icon: Icons.style_rounded,
                                  accentColor: Colors.deepPurpleAccent,
                                  theme: theme,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    ref
                                        .read(
                                          mainNavigationTabProvider.notifier,
                                        )
                                        .setTab(3);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Exam Twin Speaking Simulator
                              Expanded(
                                child: _buildSmallHubCard(
                                  title: isPersian
                                      ? 'شبیه‌ساز آیلتس'
                                      : 'Exam Twin',
                                  subtitle: isPersian
                                      ? 'ارزیابی رسمی ۴ معیار'
                                      : '4 IELTS Bands',
                                  badge: 'IELTS',
                                  icon: Icons.record_voice_over_rounded,
                                  accentColor: Colors.tealAccent.shade700,
                                  theme: theme,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    ExamTwinSheet.show(context);
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              // C1 Native Upgrade Studio
                              Expanded(
                                child: _buildSmallHubCard(
                                  title: isPersian
                                      ? 'ارتقای اصطلاحات'
                                      : 'C1 Studio',
                                  subtitle: isPersian
                                      ? 'تبدیل متن به نیتیو'
                                      : 'Native Recast',
                                  badge: 'C1',
                                  icon: Icons.auto_awesome_rounded,
                                  accentColor: Colors.indigoAccent,
                                  theme: theme,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    C1UpgradeStudioSheet.show(context);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 49-Day Roadmap Planner Button
                              Expanded(
                                child: _buildSmallHubCard(
                                  title: isPersian ? 'نقشه ۴۹ روزه' : 'Roadmap',
                                  subtitle: isPersian
                                      ? 'تسک‌های گام‌به‌گام'
                                      : 'Curriculum',
                                  badge: 'Day $currentDay',
                                  icon: Icons.calendar_month_rounded,
                                  accentColor: Colors.amber.shade700,
                                  theme: theme,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    ref
                                        .read(
                                          mainNavigationTabProvider.notifier,
                                        )
                                        .setTab(1);
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // 5. Active Error Genome Section
                          ActiveErrorGenomeSection(isPersian: isPersian),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitcher({
    required AppHubMode currentMode,
    required bool isPersian,
    required bool isDark,
    required ThemeData theme,
    required void Function(AppHubMode) onModeSelected,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151926) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModePill(
              title: isPersian ? 'زبان عمومی (لغات و متون)' : 'General Hub',
              icon: Icons.auto_stories_rounded,
              isSelected: currentMode == AppHubMode.general,
              activeColor: theme.colorScheme.primary,
              theme: theme,
              onTap: () => onModeSelected(AppHubMode.general),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildModePill(
              title: isPersian ? 'پلن اختصاصی VIP' : 'VIP Studio',
              icon: Icons.workspace_premium_rounded,
              isSelected: currentMode == AppHubMode.pro,
              activeColor: Colors.amber.shade700,
              theme: theme,
              onTap: () => onModeSelected(AppHubMode.pro),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection({
    required String name,
    required String greeting,
    required int streak,
    required int score,
    required String level,
    required ThemeData theme,
    required bool isDark,
    required bool isPersian,
    required VoidCallback onLeaderboardTap,
  }) {
    return Row(
      children: [
        // Avatar with subtle glow
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name.characters.first : 'U',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Greeting & Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Streak Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '$streak ${isPersian ? 'روز' : 'd'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // XP Badge
        InkWell(
          onTap: onLeaderboardTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, size: 15, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyMissionHeroCard({
    required int day,
    required int completedCount,
    required int totalCount,
    required double progress,
    required ThemeData theme,
    required bool isDark,
    required bool isPersian,
    required VoidCallback onStartMission,
  }) {
    return ThreeDimensionalParallaxCard(
      borderRadius: BorderRadius.circular(24),
      glowColor: theme.colorScheme.primary.withValues(alpha: 0.25),
      onTap: onStartMission,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151926) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isPersian ? 'روز $day از ۴۹' : 'Day $day of 49',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPersian
                          ? 'ماموریت همگام‌سازی روز'
                          : 'Daily Sync Mission',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$completedCount / $totalCount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isPersian
                        ? (progress >= 1.0
                              ? '🎉 تمام تسک‌های امروز تکمیل شدند!'
                              : 'تسک‌های ویدیویی، واژگان و اسپیکینگ روز $day منتظر شما هستند.')
                        : (progress >= 1.0
                              ? '🎉 All tasks completed for today!'
                              : 'Listening, Vocabulary & Speaking missions ready.'),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onStartMission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(
                    isPersian ? 'مشاهده تسک‌ها' : 'View Tasks',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveVoiceMentorCard({
    required ThemeData theme,
    required bool isDark,
    required bool isPersian,
    required VoidCallback onTap,
  }) {
    return ThreeDimensionalParallaxCard(
      borderRadius: BorderRadius.circular(24),
      glowColor: Colors.tealAccent.shade400.withValues(alpha: 0.3),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131726) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.tealAccent.shade400.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Glowing 3D Orb Icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.tealAccent.shade400, Colors.deepPurpleAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isPersian ? 'مربی صوتی زنده' : 'Live Voice Mentor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.tealAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'Gemini 3.8',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPersian
                        ? 'مکالمه روان نیتیو با تحلیل بلادرنگ و تصحیح تاخیری'
                        : 'Real-time native speaking practice with zero latency',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallHubCard({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color accentColor,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ThreeDimensionalParallaxCard(
      borderRadius: BorderRadius.circular(20),
      glowColor: accentColor.withValues(alpha: 0.2),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151926) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
