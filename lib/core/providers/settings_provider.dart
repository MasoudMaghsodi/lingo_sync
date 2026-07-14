import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  // تغییر در این خط
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
}

@Riverpod(keepAlive: true)
class IsPersian extends _$IsPersian {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool('isPersian') ?? false;
  }

  void toggleLanguage() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool('isPersian', state);
  }
}

@Riverpod(keepAlive: true)
class IsDarkMode extends _$IsDarkMode {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool('isDarkMode') ?? false;
  }

  void toggleTheme() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool('isDarkMode', state);
  }
}
