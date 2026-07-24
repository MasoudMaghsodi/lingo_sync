import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/main_navigation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/app_messenger.dart';
import '../../application/auth_controller.dart';
import '../../domain/auth_status.dart';
import '../pages/awaiting_approval_page.dart';
import '../pages/login_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authControllerProvider);

    ref.listen<AuthStatus>(authControllerProvider, (previous, next) {
      if (next is AuthError) {
        final isPersian = ref.read(isPersianProvider);

        // حذف استرینگ‌های هاردکد شده و اتصال به معماری چندزبانگی
        final message = switch (next.reason) {
          AuthErrorReason.approvalCheckFailed => AppLocalizations.getString(
            'approval_check_failed',
            isPersian,
          ),
        };

        // اطمینان از اینکه اگر کلید در فایل زبان نبود، پیامِ خالی نشان داده نشود (Fallback)
        final displayMessage = message == 'approval_check_failed'
            ? (isPersian
                  ? 'خطا در بررسی وضعیت. اتصال را بررسی کنید.'
                  : 'Connection error.')
            : message;

        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(displayMessage)),
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
