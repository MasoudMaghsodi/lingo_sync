import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/result/result.dart';

/// Wraps Supabase Auth plus the minimal profile bootstrap that has to
/// happen right after a successful sign-up.
///
/// Authentication (who are you) and authorization (are you allowed in)
/// change for different reasons and shouldn't live in the same class.
class AuthRepository {
  final supabase.SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<supabase.AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;
  supabase.User? get currentUser => _supabase.auth.currentUser;

  Future<Result<supabase.AuthResponse>> signUp({
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
        try {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'full_name': fullName,
          });
        } catch (e, st) {
          logger.warning(
            'Failed to create profile row after signup',
            context: 'AuthRepository.signUp',
            error: e is Exception ? e : Exception(e.toString()),
            stackTrace: st,
            data: {'userId': user.id},
          );
        }
      }

      return Result.success(response);
    } on supabase.AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (e, st) {
      return Result.failure(
        UnknownException(e.toString(), originalException: e, stackTrace: st),
      );
    }
  }

  Future<Result<supabase.AuthResponse>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return Result.success(response);
    } on supabase.AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (e, st) {
      return Result.failure(
        UnknownException(e.toString(), originalException: e, stackTrace: st),
      );
    }
  }

  Future<void> signOut() => _supabase.auth.signOut();

  /// تبدیل ارورهای خام دیتابیس به ارورهای استاندارد سیستم خودمان
  AuthException _mapAuthException(supabase.AuthException e) {
    final msg = e.message.toLowerCase();
    String code = 'unknown';

    if (msg.contains('invalid') &&
        (msg.contains('credential') || msg.contains('login'))) {
      code = 'invalid_credentials';
    } else if (msg.contains('already') ||
        msg.contains('registered') ||
        msg.contains('exists')) {
      code = 'email_in_use';
    } else if (msg.contains('password')) {
      code = 'weak_password';
    }

    return AuthException(e.message, code: code);
  }
}
