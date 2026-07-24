import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_sync/core/app/app.dart';

import 'core/config/app_bootstrap.dart';
import 'core/providers/settings_provider.dart';

Future<void> main() async {
  // تمام پیچیدگی‌ها در کلاس Bootstrap پنهان شد (Encapsulation)
  final sharedPreferences = await AppBootstrap.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const LingoSyncApp(),
    ),
  );
}
