import 'package:supabase_flutter/supabase_flutter.dart';

/// Owns the "is this user allowed into the app" concern, which today is
/// modeled as `user_stats.is_approved`. Kept separate from
/// [AuthRepository] on purpose — see that file's doc comment.
class ApprovalRepository {
  final SupabaseClient _supabase;

  ApprovalRepository(this._supabase);

  /// Emits the current approval flag immediately, then again every time it
  /// changes — e.g. the moment an admin flips it in the dashboard, the
  /// waiting screen updates itself with no polling and no manual refetch.
  Stream<bool> watchApprovalStatus(String userId) {
    return _supabase
        .from('user_stats')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map(
          (rows) => rows.isNotEmpty
              ? (rows.first['is_approved'] as bool? ?? false)
              : false,
        );
  }
}
