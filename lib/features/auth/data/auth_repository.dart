import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;

  Future<Either<String, AuthResponse>> signUp(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return Right(response);
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left('خطای نامشخص در ثبت‌نام: $e');
    }
  }

  Future<Either<String, AuthResponse>> signIn(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return Right(response);
      // ignore: unused_catch_clause
    } on AuthException catch (e) {
      return Left('ایمیل یا رمز عبور اشتباه است.');
    } catch (e) {
      return Left('خطای نامشخص در ورود: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
