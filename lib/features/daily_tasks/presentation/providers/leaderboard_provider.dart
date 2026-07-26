import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/leaderboard_entry.dart';
import 'daily_tasks_provider.dart';

part 'leaderboard_provider.g.dart';

@riverpod
Stream<List<LeaderboardEntry>> leaderboard(Ref ref) {
  return ref.watch(dailyTaskRepositoryProvider).watchLeaderboard();
}

@riverpod
String? currentUserId(Ref ref) {
  return ref.watch(dailyTaskRepositoryProvider).currentUserId;
}
