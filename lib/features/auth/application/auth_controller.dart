import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_status.dart';
import 'auth_providers.dart';

part 'auth_controller.g.dart';

// keepAlive: true — this drives the entire app's navigation (via AuthGate).
// It must not get disposed just because, momentarily, nothing happens to
// be watching it during a rebuild.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<bool>? _approvalSub;
  Timer? _refreshTimeoutTimer;

  @override
  AuthStatus build() {
    final repo = ref.watch(authRepositoryProvider);

    ref.onDispose(() {
      _authSub?.cancel();
      _approvalSub?.cancel();
      _refreshTimeoutTimer?.cancel();
    });

    _authSub = repo.authStateChanges.listen(_onAuthEvent);

    final existing = repo.currentUser;
    if (existing == null) return const AuthUnauthenticated();

    // A session already exists (e.g. app relaunched with a saved session).
    // Don't guess its approval status — start watching it and stay on the
    // splash state until the first real answer comes back.
    _watchApproval(existing);
    return const AuthInitial();
  }

  void _onAuthEvent(AuthState data) {
    final event = data.event;
    final session = data.session;

    switch (event) {
      case AuthChangeEvent.signedOut:
        _refreshTimeoutTimer?.cancel();
        _stopWatchingApproval();
        state = const AuthUnauthenticated();
        break;

      case AuthChangeEvent.initialSession:
        if (session == null) {
          state = const AuthUnauthenticated();
          break;
        }
        if (session.isExpired) {
          // Don't guess — wait for the SDK to either silently refresh the
          // token or give up. Either outcome arrives as its own event
          // below (tokenRefreshed / signedOut).
          state = const AuthInitial();
          _armRefreshTimeout();
          break;
        }
        _refreshTimeoutTimer?.cancel();
        _watchApproval(session.user);
        break;

      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
        _refreshTimeoutTimer?.cancel();
        if (session != null) _watchApproval(session.user);
        break;

      default:
        break;
    }
  }

  /// Safety net for the "waiting on a token refresh" window: if neither a
  /// `tokenRefreshed` nor a `signedOut` event shows up within a reasonable
  /// time, don't leave the user stuck on a splash screen forever — sign
  /// them out explicitly so they land back on the login page instead.
  void _armRefreshTimeout() {
    _refreshTimeoutTimer?.cancel();
    _refreshTimeoutTimer = Timer(const Duration(seconds: 8), () {
      if (state is AuthInitial) {
        ref.read(authRepositoryProvider).signOut();
      }
    });
  }

  /// Always tears down any previous approval subscription and creates a
  /// fresh one — deliberately NOT skipped even if this looks like the same
  /// user as before.
  ///
  /// The previous version of this method had a "skip if already watching
  /// this user" guard. That guard is what created a real bug: if an
  /// earlier subscription attempt happened while the session's token was
  /// stale/expiring (e.g. right around a token-expiry-then-manual-sign-in
  /// cycle), Supabase's Realtime channel for that subscription can end up
  /// silently never delivering data — the underlying websocket channel was
  /// authorized with an old JWT and never re-authenticated with the fresh
  /// one. A subsequent `signedIn` event for the "same" user id would then
  /// hit the guard and reuse that dead subscription instead of creating a
  /// new one, so the UI would show the sign-in as successful in the logs
  /// but never actually move off the login screen until the app was
  /// manually reloaded (which rebuilds this notifier from scratch).
  ///
  /// Always resubscribing costs one extra Realtime handshake in the rare
  /// case where this really is called twice for the same already-healthy
  /// subscription — a price worth paying to eliminate that failure mode
  /// entirely.
  void _watchApproval(User user) {
    _stopWatchingApproval();

    _approvalSub = ref
        .read(approvalRepositoryProvider)
        .watchApprovalStatus(user.id)
        .listen(
          (isApproved) {
            state = isApproved
                ? AuthAuthenticated(user)
                : AuthAwaitingApproval(user);
          },
          onError: (_) {
            // A failed check must never be silently read as "not approved" —
            // that ambiguity is exactly the bug this state machine exists to
            // remove.
            state = const AuthError(AuthErrorReason.approvalCheckFailed);
          },
        );
  }

  void _stopWatchingApproval() {
    _approvalSub?.cancel();
    _approvalSub = null;
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}
