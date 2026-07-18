import 'package:fpdart/fpdart.dart';
import 'package:lingo_sync/core/exceptions/app_exceptions.dart';
import 'package:lingo_sync/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../domain/auth_failure.dart';

/// Wraps Supabase Auth plus the minimal profile bootstrap that has to
/// happen right after a successful sign-up. Whether the user is *allowed
/// in* (admin approval) is a separate concern — see [ApprovalRepository].
/// Authentication (who are you) and authorization (are you allowed in)
/// change for different reasons and shouldn't live in the same class.
class AuthRepository {
  final supabase.SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<supabase.AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;
  supabase.User? get currentUser => _supabase.auth.currentUser;

  Future<Either<AuthFailure, AuthResponse>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final user = response.user;
      if (user != null) {
        // Part of the sign-up use case: every new account needs a row in
        // `profiles` so the rest of the app (leaderboard, etc.) can show a
        // name instead of a raw id. Non-fatal on failure — the account was
        // still created successfully, and the row can be repaired later.
        try {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'full_name': fullName,
          });
        } on DatabaseException catch (e) {
          logger.warning(
            'Failed to create profile row after signup',
            context: 'AuthRepository.signUp',
            error: e,
            stackTrace: e.stackTrace,
            data: {'userId': user.id},
          );
          // Non-fatal - account created successfully, profile can be repaired
        } catch (e, st) {
          logger.warning(
            'Unexpected error creating profile row',
            context: 'AuthRepository.signUp',
            error: e is Exception ? e : Exception(e.toString()),
            stackTrace: st,
            data: {'userId': user.id},
          );
        }
      }

      return Right(response);
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(AuthFailure(AuthFailureReason.network, e.toString()));
    }
  }

  Future<Either<AuthFailure, AuthResponse>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return Right(response);
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(AuthFailure(AuthFailureReason.network, e.toString()));
    }
  }

  Future<void> signOut() => _supabase.auth.signOut();

  AuthFailure _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('invalid') &&
        (msg.contains('credential') || msg.contains('login'))) {
      return AuthFailure(AuthFailureReason.invalidCredentials, e.message);
    }
    if (msg.contains('already') ||
        msg.contains('registered') ||
        msg.contains('exists')) {
      return AuthFailure(AuthFailureReason.emailInUse, e.message);
    }
    if (msg.contains('password')) {
      return AuthFailure(AuthFailureReason.weakPassword, e.message);
    }
    return AuthFailure(AuthFailureReason.unknown, e.message);
  }
}
