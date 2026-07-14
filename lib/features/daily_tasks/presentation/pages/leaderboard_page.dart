import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/settings_provider.dart';

// ==== Data layer (unchanged) ====

final _userStatsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return Supabase.instance.client
      .from('user_stats')
      .stream(primaryKey: ['id'])
      .order('score', ascending: false);
});

final _profilesProvider = FutureProvider<Map<String, String>>((ref) async {
  final data = await Supabase.instance.client
      .from('profiles')
      .select('id, full_name');

  final map = <String, String>{};
  for (final row in data as List) {
    final id = row['id']?.toString();
    final name = row['full_name']?.toString();
    if (id != null && name != null && name.trim().isNotEmpty) {
      map[id] = name;
    }
  }
  return map;
});

final leaderboardProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((
  ref,
) {
  final statsAsync = ref.watch(_userStatsStreamProvider);
  final profilesAsync = ref.watch(_profilesProvider);

  if (statsAsync.isLoading || profilesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (statsAsync.hasError) {
    return AsyncValue.error(statsAsync.error!, statsAsync.stackTrace!);
  }
  if (profilesAsync.hasError) {
    return AsyncValue.error(profilesAsync.error!, profilesAsync.stackTrace!);
  }

  final stats = statsAsync.value ?? [];
  final profiles = profilesAsync.value ?? {};

  final merged = stats.map((user) {
    final id = user['id']?.toString();
    return {...user, 'full_name': profiles[id] ?? 'Unknown'};
  }).toList();

  return AsyncValue.data(merged);
});

// ==== Bronze accent: the one metal missing from AppTheme, kept local ====
const Color _bronze = Color(0xFFB08D57);
const Color _bronzeDark = Color(0xFFC79A5E);

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardState = ref.watch(leaderboardProvider);
    final isPersian = ref.watch(isPersianProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPersian ? 'مسیر صعود' : 'The Ascent',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              isPersian
                  ? 'رتبه‌بندی زنده‌ی زبان‌آموزها'
                  : 'Live learner rankings',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
            onPressed: () {
              ref.invalidate(_userStatsStreamProvider);
              ref.invalidate(_profilesProvider);
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: isPersian ? TextDirection.rtl : TextDirection.ltr,
        child: leaderboardState.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          ),
          error: (err, stack) =>
              _ErrorState(isPersian: isPersian, error: err, theme: theme),
          data: (users) {
            if (users.isEmpty) {
              return _EmptyState(isPersian: isPersian, theme: theme);
            }
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    // Fixed outer height, but each peak fills it via Expanded
                    // instead of a hardcoded bar height — no more overflow
                    // regardless of name length or font scaling.
                    height: 300,
                    child: _SummitPodium(
                      users: users,
                      isPersian: isPersian,
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index < 3) return const SizedBox.shrink();
                      final user = users[index];
                      final isMe =
                          user['id'] ==
                          Supabase.instance.client.auth.currentUser?.id;
                      return _ClimberRow(
                        rank: index + 1,
                        user: user,
                        isMe: isMe,
                        isPersian: isPersian,
                        theme: theme,
                      );
                    }, childCount: users.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==== Podium: three peaks, each column fills fixed height via Expanded ====

class _SummitPodium extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final bool isPersian;
  final ThemeData theme;
  final bool isDark;

  const _SummitPodium({
    required this.users,
    required this.isPersian,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (users.length >= 2)
            Expanded(
              child: _Peak(
                user: users[1],
                rank: 2,
                peakFlex: 3,
                color: isDark ? Colors.white70 : Colors.blueGrey.shade300,
                theme: theme,
                isPersian: isPersian,
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 10),
          if (users.isNotEmpty)
            Expanded(
              child: _Peak(
                user: users[0],
                rank: 1,
                peakFlex: 4,
                color: theme.colorScheme.primary,
                theme: theme,
                isPersian: isPersian,
                crowned: true,
              ),
            ),
          const SizedBox(width: 10),
          if (users.length >= 3)
            Expanded(
              child: _Peak(
                user: users[2],
                rank: 3,
                peakFlex: 2,
                color: isDark ? _bronzeDark : _bronze,
                theme: theme,
                isPersian: isPersian,
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}

class _Peak extends StatelessWidget {
  final Map<String, dynamic> user;
  final int rank;
  final int peakFlex; // relative height of the colored peak bar
  final Color color;
  final ThemeData theme;
  final bool crowned;
  final bool isPersian;

  const _Peak({
    required this.user,
    required this.rank,
    required this.peakFlex,
    required this.color,
    required this.theme,
    required this.isPersian,
    this.crowned = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['full_name']?.toString() ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isMe = user['id'] == Supabase.instance.client.auth.currentUser?.id;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (crowned)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
        Container(
          width: crowned ? 56 : 46,
          height: crowned ? 56 : 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.95),
                color.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.15),
              width: isMe ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 0.5,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
            fontSize: crowned ? 13 : 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${user['score'] ?? 0} XP',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        // The peak fills whatever space remains — flex controls relative
        // height between rank 1/2/3 without any hardcoded pixel values.
        Expanded(
          flex: peakFlex,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.28),
                    color.withValues(alpha: 0.06),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: color.withValues(alpha: 0.85),
                    width: 2,
                  ),
                  left: BorderSide(color: color.withValues(alpha: 0.2)),
                  right: BorderSide(color: color.withValues(alpha: 0.2)),
                ),
              ),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==== Row for rank 4+ ====

class _ClimberRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> user;
  final bool isMe;
  final bool isPersian;
  final ThemeData theme;

  const _ClimberRow({
    required this.rank,
    required this.user,
    required this.isMe,
    required this.isPersian,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['full_name']?.toString() ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final streak = user['streak_days'] ?? 0;
    final score = user['score'] ?? 0;
    final gold = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? gold.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isMe
                ? gold.withValues(alpha: 0.6)
                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            width: isMe ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isMe
                      ? gold
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    gold.withValues(alpha: 0.9),
                    gold.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 13,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$streak ${isPersian ? "روز" : "days"}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: gold.withValues(alpha: 0.12),
                border: Border.all(color: gold.withValues(alpha: 0.4)),
              ),
              child: Text(
                '$score XP',
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==== States ====

class _EmptyState extends StatelessWidget {
  final bool isPersian;
  final ThemeData theme;
  const _EmptyState({required this.isPersian, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.terrain_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              isPersian
                  ? 'هنوز کسی مسیر رو شروع نکرده'
                  : 'No one has started climbing yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPersian
                  ? 'اولین امتیازت اولین قدم رو ثبت می‌کنه'
                  : 'Your first point starts the leaderboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool isPersian;
  final Object error;
  final ThemeData theme;
  const _ErrorState({
    required this.isPersian,
    required this.error,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              isPersian
                  ? 'رتبه‌بندی لود نشد'
                  : 'Couldn\'t load the leaderboard',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
