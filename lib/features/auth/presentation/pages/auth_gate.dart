import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/app_messenger.dart';
import 'package:lingo_sync/main_navagitions.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../application/auth_controller.dart';
import '../../domain/auth_status.dart';
import '../pages/awaiting_approval_page.dart';
import '../pages/login_page.dart';

/// The single place in the app that decides "which top-level screen is the
/// user looking at right now", driven entirely by [AuthStatus]. Nothing
/// below this widget needs to know or care about tokens, sessions, or
/// approval — each screen just gets built once the state machine says
/// it's time.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authControllerProvider);

    ref.listen<AuthStatus>(authControllerProvider, (previous, next) {
      if (next is AuthError) {
        final isPersian = ref.read(isPersianProvider);
        final message = switch (next.reason) {
          AuthErrorReason.approvalCheckFailed =>
            isPersian
                ? 'خطا در بررسی وضعیت حساب. اتصال خود را بررسی کنید.'
                : 'Could not check your approval status. Check your connection.',
        };
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });

    return switch (status) {
      AuthInitial() => const _SplashScreen(),
      AuthUnauthenticated() => const LoginPage(),
      AuthError() => const LoginPage(),
      AuthAwaitingApproval() => const AwaitingApprovalPage(),
      AuthAuthenticated() => const MainNavigation(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
