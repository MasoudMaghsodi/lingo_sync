import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppHubMode {
  general, // عمومی (واژه‌نامه، کالینز ۵۰۰، ۱۱۰۰ واژه، ۶۲۰ جمله، ایمپورت انکی، لایتنر)
  pro, // پرو VIP (پلنر ۴۹ روزه، منتور صوتی بی‌درنگ، آیلتس توئین، استودیو C1، ژنوم خطا)
}

class AppHubModeNotifier extends Notifier<AppHubMode> {
  @override
  AppHubMode build() => AppHubMode.pro; // پیش‌فرض روی حالت پرو VIP یا عمومی

  void toggleMode() {
    state = state == AppHubMode.general ? AppHubMode.pro : AppHubMode.general;
  }

  void setMode(AppHubMode mode) {
    state = mode;
  }
}

final appHubModeProvider = NotifierProvider<AppHubModeNotifier, AppHubMode>(
  AppHubModeNotifier.new,
);
