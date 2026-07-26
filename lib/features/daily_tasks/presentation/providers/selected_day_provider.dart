import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../settings/data/profile_repository.dart';

part 'selected_day_provider.g.dart';

@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt(StorageConstants.prKeyCurrentDay) ?? 1;
  }

  void setDay(int day) {
    if (state == day) return;

    state = day;
    ref
        .read(sharedPreferencesProvider)
        .setInt(StorageConstants.prKeyCurrentDay, day);

    // 🚀 سینک کردن روز با Supabase تا AI Mentor و صفحه پروفایل آپدیت شوند!
    ref.read(profileRepositoryProvider).syncCurrentDayToDatabase(day);
  }
}
