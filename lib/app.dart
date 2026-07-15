import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/app_messenger.dart';
import 'package:lingo_sync/features/auth/presentation/pages/auth_gate.dart';

import 'core/providers/settings_provider.dart';
import 'core/theme/app_theme.dart';

class LingoSyncApp extends ConsumerWidget {
  const LingoSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final isPersian = ref.watch(isPersianProvider);

    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'LingoSync',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Directionality(
        textDirection: isPersian ? TextDirection.rtl : TextDirection.ltr,
        child: const AuthGate(),
      ),
    );
  }
}
