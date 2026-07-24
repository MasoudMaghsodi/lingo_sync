// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/storage_constants.dart';
import '../logging/app_logger.dart';
import '../logging/log_level.dart';
import 'app_config.dart';

/// کلاس مدیر اجرایی که وظیفه استارت زدن تمام سرویس‌ها را قبل از اجرای اپلیکیشن دارد
abstract final class AppBootstrap {
  static Future<SharedPreferences> init() async {
    // ۱. روشن کردن موتور فلاتر
    WidgetsFlutterBinding.ensureInitialized();

    // ۲. راه‌اندازی سیستم لاگر سفارشی تو
    initializeLogger(minimumLevel: LogLevel.debug, enableConsoleOutput: true);
    logger.info('Bootstrapping application services...');

    try {
      // ۳. لود کردن متغیرهای محیطی
      await dotenv.load(fileName: ".env");

      // ۴. اجرای موازی (Parallel) تسک‌ها برای افزایش چشمگیر سرعت لودینگ اولیه اپ
      final results = await Future.wait([
        _initHive(),
        _initSupabase(),
        SharedPreferences.getInstance(),
      ]);

      logger.info('All core services bootstrapped successfully');

      // خروجی SharedPreferences در ایندکس ۲ آرایه نتایج است
      return results[2] as SharedPreferences;
    } catch (e, st) {
      logger.critical(
        'Critical failure during app bootstrap',
        error: e is Exception ? e : Exception(e.toString()),
        stackTrace: st,
        context: 'AppBootstrap',
      );
      rethrow;
    }
  }

  static Future<void> _initHive() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(StorageConstants.hiveBoxFlashcards),
      Hive.openBox(
        StorageConstants.hiveBoxCache,
      ), // باکس pending_sync رو با ثابت‌های استوریج هماهنگ کردیم
    ]);
  }

  static Future<void> _initSupabase() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }
}
