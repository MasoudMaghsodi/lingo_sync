import 'package:supabase_flutter/supabase_flutter.dart';

/// Why the approval check itself failed — again, no UI strings here.
enum AuthErrorReason { approvalCheckFailed }

/// The single source of truth for "where is the user in the auth/approval
/// lifecycle". Using a sealed class instead of a handful of independent
/// booleans (`isLoading`, `isApproved`, `currentUser`) makes invalid
/// combinations unrepresentable — there is no way to be simultaneously
/// "loading" and "awaiting approval". That ambiguity is exactly what let
/// the old code mistake an expired-token / failed-fetch error for
/// "not approved yet".
sealed class AuthStatus {
  const AuthStatus();
}

/// Splash/bootstrap state: we don't know yet whether there's a valid
/// session, or we're waiting for a token refresh to resolve.
class AuthInitial extends AuthStatus {
  const AuthInitial();
}

/// No valid session. Show the login/sign-up screen.
class AuthUnauthenticated extends AuthStatus {
  const AuthUnauthenticated();
}

/// Logged in, but an admin hasn't approved the account yet.
class AuthAwaitingApproval extends AuthStatus {
  final User user;
  const AuthAwaitingApproval(this.user);
}

/// Logged in and approved — the actual app.
class AuthAuthenticated extends AuthStatus {
  final User user;
  const AuthAuthenticated(this.user);
}

/// Something failed outside the normal flow (e.g. the approval check
/// itself errored out). This is deliberately its own state instead of
/// silently falling back to [AuthAwaitingApproval], so a transient error
/// never gets mistaken for a real "you're not approved" answer.
class AuthError extends AuthStatus {
  final AuthErrorReason reason;
  const AuthError(this.reason);
}
