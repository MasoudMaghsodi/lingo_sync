import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_constants.dart';
import '../logging/app_logger.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
}

@Riverpod(keepAlive: true)
class IsPersian extends _$IsPersian {
  @override
  bool build() {
    return ref
            .watch(sharedPreferencesProvider)
            .getBool(StorageConstants.prKeyLanguage) ??
        false;
  }

  Future<void> toggleLanguage() async {
    final previousState = state;

    // ۱. به‌روزرسانی خوش‌بینانه برای سرعت بالای UI (بدون مکث)
    state = !state;

    try {
      // ۲. تلاش برای ذخیره در حافظه فیزیکی دستگاه
      final success = await ref
          .read(sharedPreferencesProvider)
          .setBool(StorageConstants.prKeyLanguage, state);

      if (!success) {
        // ۳. رول‌بک در صورت شکست عملیات نوشتن روی دیسک
        state = previousState;
        logger.warning(
          'Failed to save language preference to storage',
          context: 'SettingsProvider',
        );
      }
    } catch (e) {
      // ۴. مدیریت خطاهای غیرمنتظره سیستم‌عامل
      state = previousState;
      logger.error(
        'Exception while saving language preference',
        error: e as Exception,
        context: 'SettingsProvider',
      );
    }
  }
}

@Riverpod(keepAlive: true)
class IsDarkMode extends _$IsDarkMode {
  @override
  bool build() {
    return ref
            .watch(sharedPreferencesProvider)
            .getBool(StorageConstants.prKeyThemeMode) ??
        false;
  }

  Future<void> toggleTheme() async {
    final previousState = state;

    state = !state;

    try {
      final success = await ref
          .read(sharedPreferencesProvider)
          .setBool(StorageConstants.prKeyThemeMode, state);

      if (!success) {
        state = previousState;
        logger.warning(
          'Failed to save theme preference to storage',
          context: 'SettingsProvider',
        );
      }
    } catch (e) {
      state = previousState;
      logger.error(
        'Exception while saving theme preference',
        error: e as Exception,
        context: 'SettingsProvider',
      );
    }
  }
}
