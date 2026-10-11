import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/features/auth/domain/auth_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthStatus sealed hierarchy', () {
    test('AuthInitial is an AuthStatus', () {
      const status = AuthInitial();
      expect(status, isA<AuthStatus>());
    });

    test('AuthUnauthenticated is an AuthStatus', () {
      const status = AuthUnauthenticated();
      expect(status, isA<AuthStatus>());
    });

    test('AuthAwaitingApproval holds the given user', () {
      final user = User(
        id: 'u123',
        appMetadata: {},
        userMetadata: {'full_name': 'Test User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final status = AuthAwaitingApproval(user);

      expect(status, isA<AuthStatus>());
      expect(status.user.id, 'u123');
      expect(status.user.userMetadata?['full_name'], 'Test User');
    });

    test('AuthAuthenticated holds the verified user', () {
      final user = User(
        id: 'u456',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final status = AuthAuthenticated(user);

      expect(status, isA<AuthStatus>());
      expect(status.user.id, 'u456');
    });

    test('AuthError holds the failure reason', () {
      const status = AuthError(AuthErrorReason.approvalCheckFailed);

      expect(status, isA<AuthStatus>());
      expect(status.reason, AuthErrorReason.approvalCheckFailed);
    });
  });
}
