/// A single row in the global leaderboard — the domain-level merge of a
/// `user_stats` row with its corresponding `profiles` row (full name,
/// avatar). Exists so `LeaderboardPage`'s widgets read named, typed
/// fields instead of indexing into a raw merged `Map<String, dynamic>`.
class LeaderboardEntry {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final int score;
  final int streakDays;

  const LeaderboardEntry({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    required this.score,
    required this.streakDays,
  });

  factory LeaderboardEntry.fromStatsRow(
    Map<String, dynamic> statsRow,
    Map<String, dynamic>? profile,
  ) {
    final name = profile?['full_name'] as String?;
    return LeaderboardEntry(
      id: statsRow['id']?.toString() ?? '',
      fullName: (name != null && name.trim().isNotEmpty) ? name : 'Unknown',
      avatarUrl: profile?['avatar_url'] as String?,
      score: (statsRow['score'] as num?)?.toInt() ?? 0,
      streakDays: (statsRow['streak_days'] as num?)?.toInt() ?? 0,
    );
  }
}
