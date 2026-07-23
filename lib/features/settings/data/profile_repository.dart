import 'dart:async';
import 'dart:typed_data';

import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/result/result.dart';
import 'package:lingo_sync/core/services/error_handler_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

part 'profile_repository.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(Supabase.instance.client);
}

/// A merged, read-model view of the current user across `profiles` and
/// `user_stats` — the settings drawer needs fields from both tables, and
/// callers shouldn't need to know that split.
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? englishLevel;
  final String? avatarUrl;
  final int score;
  final int streakDays;
  final int currentDay;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.englishLevel,
    required this.avatarUrl,
    required this.score,
    required this.streakDays,
    required this.currentDay,
  });
}

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  /// Streams the current user's profile + stats, merged, updating live if
  /// either row changes (e.g. score ticking up from another device).
  ///
  /// This deliberately merges two realtime streams manually with a plain
  /// `StreamController`, rather than combining two Riverpod providers —
  /// see `leaderboard_page.dart` for why "a provider watching two other
  /// providers" is a real footgun. This lives entirely outside Riverpod's
  /// provider graph, sidestepping that class of bug entirely.
  ///
  /// Both subscriptions pass an `onError` handler that forwards into the
  /// controller as a stream error — without this, a subscription failure
  /// (e.g. a table not yet added to the `supabase_realtime` publication)
  /// surfaces as an uncaught top-level exception instead of a normal
  /// `AsyncValue.error` the UI can render gracefully. This is exactly what
  /// happened with `profiles` before it was added to the publication (see
  /// the accompanying SQL fix) — this handler is what makes any *future*
  /// table with the same oversight fail safely instead of crashing.
  Stream<UserProfile> watchCurrentUserProfile() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.error(
        const AuthException('No authenticated user', code: 'not_authenticated'),
      );
    }

    // ignore: close_sinks
    late final StreamController<UserProfile> controller;
    Map<String, dynamic>? latestProfile;
    Map<String, dynamic>? latestStats;

    void emitIfReady() {
      if (latestStats == null) return;
      controller.add(
        UserProfile(
          id: user.id,
          email: latestStats!['email'] as String? ?? user.email ?? '',
          fullName: latestProfile?['full_name'] as String?,
          englishLevel: latestProfile?['english_level'] as String?,
          avatarUrl: latestProfile?['avatar_url'] as String?,
          score: (latestStats!['score'] as num?)?.toInt() ?? 0,
          streakDays: (latestStats!['streak_days'] as num?)?.toInt() ?? 0,
          currentDay: (latestStats!['current_day'] as num?)?.toInt() ?? 1,
        ),
      );
    }

    void forwardError(Object error, StackTrace stackTrace) {
      controller.addError(
        errorHandler.toAppException(
          error,
          stackTrace,
          context: 'ProfileRepository.watchCurrentUserProfile',
        ),
        stackTrace,
      );
    }

    late final StreamSubscription profileSub;
    late final StreamSubscription statsSub;

    controller = StreamController<UserProfile>(
      onListen: () {
        profileSub = _supabase
            .from('profiles')
            .stream(primaryKey: ['id'])
            .eq('id', user.id)
            .listen((rows) {
              latestProfile = rows.isNotEmpty ? rows.first : null;
              emitIfReady();
            }, onError: forwardError);

        statsSub = _supabase
            .from('user_stats')
            .stream(primaryKey: ['id'])
            .eq('id', user.id)
            .listen((rows) {
              latestStats = rows.isNotEmpty ? rows.first : null;
              emitIfReady();
            }, onError: forwardError);
      },
      onCancel: () {
        profileSub.cancel();
        statsSub.cancel();
      },
    );

    return controller.stream;
  }

  Future<Result<void>> updateProfile({
    String? fullName,
    String? englishLevel,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Result<void>.failure(
        const AuthException('No authenticated user', code: 'not_authenticated'),
      );
    }

    try {
      final update = <String, dynamic>{};
      if (fullName != null) update['full_name'] = fullName;
      if (englishLevel != null) update['english_level'] = englishLevel;
      if (update.isEmpty) return Result<void>.success(null);

      await _supabase.from('profiles').update(update).eq('id', user.id);
      return Result<void>.success(null);
    } catch (e, st) {
      return Result<void>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'ProfileRepository.updateProfile',
        ),
      );
    }
  }

  /// Uploads a new avatar image to Supabase Storage (bucket `avatars`,
  /// path scoped to the user's own folder so the storage policies allow
  /// it) and updates the profile's `avatar_url` to the resulting public
  /// URL.
  Future<Result<String>> uploadAvatar(
    List<int> bytes, {
    required String fileExtension,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Result<String>.failure(
        const AuthException('No authenticated user', code: 'not_authenticated'),
      );
    }

    try {
      final path = '${user.id}/avatar.$fileExtension';
      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      final bustedUrl =
          '$publicUrl?updated=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase
          .from('profiles')
          .update({'avatar_url': bustedUrl})
          .eq('id', user.id);

      return Result<String>.success(bustedUrl);
    } catch (e, st) {
      return Result<String>.failure(
        errorHandler.toAppException(
          e,
          st,
          context: 'ProfileRepository.uploadAvatar',
        ),
      );
    }
  }
}
