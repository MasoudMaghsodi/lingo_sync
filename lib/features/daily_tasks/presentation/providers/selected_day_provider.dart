import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/providers/settings_provider.dart';

part 'selected_day_provider.g.dart';

@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  int build() {
    // 🚀 خواندن روزِ ذخیره‌شده در زمان باز شدن اپلیکیشن (با مقدار پیش‌فرض ۱)
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt(StorageConstants.prKeyCurrentDay) ?? 1;
  }

  void setDay(int day) {
    if (state == day) return;

    state = day;
    // 🚀 ذخیره‌سازی روز انتخاب‌شده در دیسک به صورت همزمان
    ref
        .read(sharedPreferencesProvider)
        .setInt(StorageConstants.prKeyCurrentDay, day);
  }
}
