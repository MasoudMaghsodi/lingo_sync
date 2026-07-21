import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/profile_repository.dart';

part 'profile_provider.g.dart';

/// Live view of the current user's profile + stats, merged. Used by the
/// settings drawer to show name/email/avatar/level/stats, and kept alive
/// so it doesn't rebuild the stream subscription every time the drawer is
/// opened and closed.
@Riverpod(keepAlive: true)
Stream<UserProfile> currentUserProfile(Ref ref) {
  return ref.watch(profileRepositoryProvider).watchCurrentUserProfile();
}
