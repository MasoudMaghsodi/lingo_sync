// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/log_level.dart';
import 'core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger FIRST - before any other operations
  initializeLogger(minimumLevel: LogLevel.debug, enableConsoleOutput: true);
  logger.info('Application starting');

  // 1. راه‌اندازی دیتابیس آفلاین فلاتر
  try {
    await Hive.initFlutter();
    await Hive.openBox('flashcards_cache');
    await Hive.openBox('pending_sync');
    logger.info('Hive databases initialized');
  } catch (e, st) {
    logger.critical(
      'Failed to initialize Hive',
      error: e is Exception ? e : Exception(e.toString()),
      stackTrace: st,
      context: 'main',
    );
    rethrow;
  }

  try {
    await dotenv.load(fileName: ".env");
    logger.info('Environment variables loaded');
  } catch (e, st) {
    logger.critical(
      'Failed to load .env file',
      error: e is Exception ? e : Exception(e.toString()),
      stackTrace: st,
      context: 'main',
    );
    rethrow;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    logger.info('Supabase initialized');
  } catch (e, st) {
    logger.critical(
      'Failed to initialize Supabase',
      error: e is Exception ? e : Exception(e.toString()),
      stackTrace: st,
      context: 'main',
    );
    rethrow;
  }

  final sharedPreferences = await SharedPreferences.getInstance();
  logger.info('SharedPreferences loaded');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const LingoSyncApp(),
    ),
  );
}
