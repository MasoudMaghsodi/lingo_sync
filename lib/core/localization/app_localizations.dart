// lib/core/localization/app_localizations.dart
class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'smart_anki': 'Smart Anki',
      'archive': 'Vocabulary Archive',
      'all': 'All',
      'no_words': 'No words found.',
      'box': 'Box',
      'forgot': 'Forgot',
      'remembered': 'Remembered',
      'tap_to_reveal': 'Tap to reveal answer',
      'example': 'Example:',
      'antonyms': 'Antonyms: ',
      'synonyms': 'Synonyms by level:',
      'folders': 'Folders',
      'add_folder': 'New Folder',
      'filters': 'Filters',
      'clear_filters': 'Clear Filters',
      'part_of_speech': 'Part of Speech',
      'definition': 'Definition',
      'focus_finished': 'Focus session finished! Time to rest.',
      'custom_time_hint': 'Enter minutes',
      'save': 'Save',
      'cancel': 'Cancel',

      // کلیدهای جدید اضافه شده
      'tasks_title': '50-Day TOEFL Plan',
      'day': 'Day',
      'no_tasks': 'No tasks defined for this day.',
      'leaderboard': 'Global Leaderboard',
      'no_activity': 'No activity yet!',
      'fire_days': 'Days',
      'fetching_data': 'Fetching Data...',
      'connecting': 'Connecting...',
      'initializing': 'Initializing...',
      'thinking': 'Thinking...',
      'mentor_speaking': 'Mentor is speaking',
      'listening': 'Listening...',
    },
    'fa': {
      'smart_anki': 'جعبه لایتنر هوشمند',
      'archive': 'آرشیو جامع لغات',
      'all': 'همه',
      'no_words': 'لغتی یافت نشد.',
      'box': 'جعبه',
      'forgot': 'فراموش کردم',
      'remembered': 'یادم بود',
      'tap_to_reveal': 'برای دیدن جواب روی کارت ضربه بزنید',
      'example': 'مثال:',
      'antonyms': 'متضادها: ',
      'synonyms': 'مترادف‌ها بر اساس سطح:',
      'folders': 'پوشه‌ها',
      'add_folder': 'پوشه جدید',
      'filters': 'فیلترها',
      'clear_filters': 'حذف فیلترها',
      'part_of_speech': 'نقش کلمه',
      'definition': 'معنی / تعریف',
      'focus_finished': 'زمان تمرکز به پایان رسید! وقت استراحت است.',
      'custom_time_hint': 'دقیقه را وارد کنید',
      'save': 'ذخیره',
      'cancel': 'انصراف',

      // کلیدهای جدید اضافه شده
      'tasks_title': 'برنامه ۵۰ روزه تافل',
      'day': 'روز',
      'no_tasks': 'برای این روز تسکی تعریف نشده.',
      'leaderboard': 'رده‌بندی رقابتی',
      'no_activity': 'هنوز کسی فعالیتی نداشته است!',
      'fire_days': 'روز آتشین',
      'fetching_data': 'در حال دریافت اطلاعات...',
      'connecting': 'در حال اتصال به سرور...',
      'initializing': 'در حال آماده‌سازی...',
      'thinking': 'در حال پردازش...',
      'mentor_speaking': 'استاد صحبت می‌کند',
      'listening': 'در حال شنیدن...',
    },
  };

  static String getString(String key, bool isPersian) {
    final lang = isPersian ? 'fa' : 'en';
    return _localizedValues[lang]?[key] ?? key;
  }
}
