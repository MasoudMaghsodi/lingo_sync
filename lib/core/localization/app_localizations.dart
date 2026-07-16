// lib/core/localization/app_localizations.dart

/// Centralized bilingual (Persian/English) string table for the whole app.
///
/// Every user-facing string that isn't dynamic content from the backend
/// should live here, keyed by a short snake_case identifier, instead of
/// being written inline as `isPersian ? '...' : '...'` inside a widget.
/// That inline pattern is how the same phrase ends up duplicated (and
/// eventually drifting out of sync) across multiple files.
class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // ==== Dictionary / Flashcards (existing) ====
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

      // ==== Daily tasks / leaderboard (existing) ====
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

      // ==== Bottom navigation (Phase 3A) ====
      'nav_tasks': 'Tasks',
      'nav_dictionary': 'Dictionary',
      'nav_review': 'Review',
      'nav_leaderboard': 'Leaderboard',

      // ==== Daily tasks page (Phase 3A) ====
      'tasks_loading_error': 'Something went wrong while loading your tasks.',

      // ==== Awaiting approval page (Phase 3A) ====
      'awaiting_approval_title': 'Awaiting Admin Approval',
      'awaiting_approval_body':
          'Your account has been created.\nThis page will unlock '
          'automatically once approved.',
      'logout': 'Logout',

      // ==== Grammar vault page (Phase 3A) ====
      'grammar_vault_title': 'Grammar Vault',
      'no_grammar_points': 'No grammar points found.',
      'grammar_points_suffix': 'Grammar points',

      // ==== AI Mentor sheet (Phase 3A) ====
      'mentor_session_ended': 'Session Ended (Tap to restart)',
      'mentor_no_internet': 'No Internet Connection!',
      'mentor_listening': 'Mentor is listening...',

      // ==== Floating Pomodoro (Phase 3A) ====
      'pomodoro_set_focus_time': 'Set Focus Time',
      'pomodoro_enter_minutes_hint': 'Enter minutes (e.g. 25)',
      'pomodoro_focus_label': 'Focus',
      'pomodoro_done_label': 'Done! 🎉',

      // ==== Dictionary page (Phase 3B) ====
      'dictionary_video_section_title': 'Smart Video Lesson',
      'dictionary_youtube_hint': 'Enter a YouTube link...',
      'dictionary_extract_button': 'Extract Summary, Grammar & Vocabulary',
      'dictionary_search_hint': 'Advanced word search...',
      'dictionary_search_placeholder': 'Search a word to see the AI magic.',
      'added_to_flashcards': 'Added to your flashcard deck!',
      'save_error': 'Error saving',
      'dictionary_definition_title': 'Definition',
      'dictionary_examples_title': 'Examples',
      'dictionary_synonyms_hint': 'Synonyms (long-press = add to Anki)',
      'add_to_review': 'Add to Review (Anki)',

      // ==== Video lesson page (Phase 3B) ====
      'note_saved': 'Note saved.',
      'note_save_error': 'Error saving note',
      'ai_question_limit': 'Limit of 2 questions per hour reached!',
      'ai_connection_error': 'Error connecting to AI',
      'grammar_added': 'Grammar added to your flashcards',
      'ask_ai_mentor_title': 'Ask the AI Mentor',
      'ai_question_limit_notice':
          'Limit: 2 questions per hour.\nOnly questions about this video!',
      'ai_question_hint': "What did this expression mean in the video?...",
      'send_question': 'Send Question',
      'ai_answer_label': 'AI Answer:',
      'video_lesson_title': 'Video Lesson',
      'tab_summary_notes': 'Summary & Notes',
      'tab_transcript': 'Transcript',
      'tab_grammar': 'Kid-Friendly Grammar',
      'tab_vocabulary': 'Vocabulary',
      'chat_with_ai': 'Chat with AI',
      'smart_summary_title': 'Smart Summary',
      'personal_notes_title': 'Your Personal Notes',
      'note_hint':
          'Write down important points from this video...\n\n- First '
          'point\n- Second point',
      'save_note_button': 'Save Note to Server',
      'add_to_anki': 'Add to Anki',
      'example_in_video': 'Example in the video:',
      'childlike_explanation_prefix': 'Kid-friendly explanation:',
      'add_to_leitner_tooltip': 'Add to flashcards',
      'synonyms_level_hint': 'Synonyms by level (long-press = add):',
      'word_added_to_leitner': 'added to your flashcards',

      // ==== Flashcards page (Phase 3B) ====
      'flashcards_loading_error': 'Error loading data',
      'flashcards_all_done': 'All caught up for today!',
      'cards_left_suffix': 'cards left',
      'archive_all_tooltip': 'Archive',

      // ==== All flashcards / archive page (Phase 3B) ====
      'create_folder_title': 'Create Folder',
      'folder_name_hint': 'Folder Name',
      'manage_folder_title': 'Manage Folder',
      'rename': 'Rename',
      'delete_folder_action': 'Delete (Move words to General)',
      'rename_folder_title': 'Rename Folder',
      'new_name_hint': 'New Name',
      'move_to_folder_title': 'Move to folder:',
      'move_error': 'Error moving card',
      'move_tooltip': 'Move',

      // ==== Leaderboard page (Phase 3B) ====
      'leaderboard_title': 'The Ascent',
      'leaderboard_subtitle': 'Live learner rankings',
      'leaderboard_empty_title': 'No one has started climbing yet',
      'leaderboard_empty_subtitle': 'Your first point starts the leaderboard',
      'leaderboard_error_title': "Couldn't load the leaderboard",
      'days_suffix': 'days',

      // ==== Login page (Phase 3B) ====
      'login_tagline': 'The Ultimate Path to Fluency',
      'full_name_label': 'Full Name',
      'name_min_length_error': 'Name must be at least 3 characters',
      'letters_only_error': 'Only letters allowed',
      'email_label': 'Email',
      'invalid_email_error': 'Invalid email format',
      'password_label': 'Password',
      'password_min_length_error': 'Min 8 characters required',
      'login_button': 'Login',
      'create_account_button': 'Create Account',
      'login_toggle': 'Login',
      'signup_toggle': 'Sign up',
      'unexpected_error': 'An unexpected error occurred',
    },
    'fa': {
      // ==== Dictionary / Flashcards (existing) ====
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

      // ==== Daily tasks / leaderboard (existing) ====
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

      // ==== Bottom navigation (Phase 3A) ====
      'nav_tasks': 'تسک‌ها',
      'nav_dictionary': 'دیکشنری',
      'nav_review': 'مرور',
      'nav_leaderboard': 'رتبه‌بندی',

      // ==== Daily tasks page (Phase 3A) ====
      'tasks_loading_error': 'مشکلی در دریافت اطلاعات پیش آمد.',

      // ==== Awaiting approval page (Phase 3A) ====
      'awaiting_approval_title': 'در انتظار تایید ادمین',
      'awaiting_approval_body':
          'حساب شما ساخته شد.\nبه‌محض تایید مدیریت، این صفحه خودکار باز '
          'می‌شود.',
      'logout': 'خروج از حساب',

      // ==== Grammar vault page (Phase 3A) ====
      'grammar_vault_title': 'گنجینه گرامرها',
      'no_grammar_points': 'هنوز گرامری ثبت نشده است.',
      'grammar_points_suffix': 'نکته گرامری',

      // ==== AI Mentor sheet (Phase 3A) ====
      'mentor_session_ended': 'سشن پایان یافت (لمس برای شروع مجدد)',
      'mentor_no_internet': 'اینترنت قطع شد!',
      'mentor_listening': 'استاد می‌شنود...',

      // ==== Floating Pomodoro (Phase 3A) ====
      'pomodoro_set_focus_time': 'تنظیم زمان تمرکز',
      'pomodoro_enter_minutes_hint': 'دقیقه را وارد کنید (مثلا ۲۵)',
      'pomodoro_focus_label': 'تمرکز',
      'pomodoro_done_label': 'تمام شد! 🎉',

      // ==== Dictionary page (Phase 3B) ====
      'dictionary_video_section_title': 'درسنامه ویدیویی هوشمند',
      'dictionary_youtube_hint': 'لینک یوتیوب را وارد کنید...',
      'dictionary_extract_button': 'استخراج خلاصه، گرامر و لغات',
      'dictionary_search_hint': 'جستجوی پیشرفته لغت...',
      'dictionary_search_placeholder':
          'کلمه‌ای را جستجو کنید تا جادوی هوش مصنوعی را ببینید.',
      'added_to_flashcards': 'به جعبه لایتنر اضافه شد!',
      'save_error': 'خطا در ذخیره',
      'dictionary_definition_title': 'معنی / Definition',
      'dictionary_examples_title': 'مثال‌ها / Examples',
      'dictionary_synonyms_hint': 'مترادف‌ها (لانگ‌پرس = افزودن به انکی)',
      'add_to_review': 'افزودن به مرور (Anki)',

      // ==== Video lesson page (Phase 3B) ====
      'note_saved': 'یادداشت ذخیره شد.',
      'note_save_error': 'خطا در ذخیره یادداشت',
      'ai_question_limit': 'محدودیت ۲ سوال در ساعت!',
      'ai_connection_error': 'خطا در ارتباط با هوش مصنوعی',
      'grammar_added': 'گرامر به لایتنر اضافه شد',
      'ask_ai_mentor_title': 'پرسش از منتور AI',
      'ai_question_limit_notice':
          'محدودیت: ۲ پرسش در ساعت.\nفقط سوالات مرتبط با همین ویدیو!',
      'ai_question_hint': 'منظور از این اصطلاح در ویدیو چه بود؟...',
      'send_question': 'ارسال پرسش',
      'ai_answer_label': 'پاسخ هوش مصنوعی:',
      'video_lesson_title': 'درسنامه ویدیویی',
      'tab_summary_notes': 'خلاصه و یادداشت',
      'tab_transcript': 'ترنسکریپت',
      'tab_grammar': 'گرامر کودکانه',
      'tab_vocabulary': 'لغات',
      'chat_with_ai': 'گپ با AI',
      'smart_summary_title': 'خلاصه هوشمند',
      'personal_notes_title': 'یادداشت شخصی شما',
      'note_hint':
          'نکات مهم این ویدیو را اینجا بنویسید...\n\n- نکته اول\n- نکته دوم',
      'save_note_button': 'ذخیره یادداشت در سرور',
      'add_to_anki': 'افزودن به انکی',
      'example_in_video': 'مثال در ویدیو:',
      'childlike_explanation_prefix': '👶 توضیحات کودکانه:',
      'add_to_leitner_tooltip': 'افزودن به جعبه لایتنر',
      'synonyms_level_hint': 'مترادف‌ها بر اساس سطح (لانگ‌پرس = افزودن):',
      'word_added_to_leitner': 'به لایتنر اضافه شد',

      // ==== Flashcards page (Phase 3B) ====
      'flashcards_loading_error': 'خطا در بارگذاری اطلاعات',
      'flashcards_all_done': 'تمام لغات امروز را مرور کردی!',
      'cards_left_suffix': 'کارت باقی‌مانده',
      'archive_all_tooltip': 'آرشیو کل لغات',

      // ==== All flashcards / archive page (Phase 3B) ====
      'create_folder_title': 'ایجاد پوشه جدید',
      'folder_name_hint': 'نام پوشه',
      'manage_folder_title': 'مدیریت پوشه',
      'rename': 'تغییر نام',
      'delete_folder_action': 'حذف پوشه (انتقال لغات به General)',
      'rename_folder_title': 'تغییر نام پوشه',
      'new_name_hint': 'نام جدید',
      'move_to_folder_title': 'انتقال به پوشه:',
      'move_error': 'خطا در انتقال',
      'move_tooltip': 'انتقال پوشه',

      // ==== Leaderboard page (Phase 3B) ====
      'leaderboard_title': 'مسیر صعود',
      'leaderboard_subtitle': 'رتبه‌بندی زنده‌ی زبان‌آموزها',
      'leaderboard_empty_title': 'هنوز کسی مسیر رو شروع نکرده',
      'leaderboard_empty_subtitle': 'اولین امتیازت اولین قدم رو ثبت می‌کنه',
      'leaderboard_error_title': 'رتبه‌بندی لود نشد',
      'days_suffix': 'روز',

      // ==== Login page (Phase 3B) ====
      'login_tagline': 'بهترین مسیر تسلط بر زبان',
      'full_name_label': 'نام و نام خانوادگی',
      'name_min_length_error': 'نام باید حداقل ۳ حرف باشد',
      'letters_only_error': 'فقط حروف مجاز است',
      'email_label': 'ایمیل',
      'invalid_email_error': 'فرمت ایمیل نامعتبر است',
      'password_label': 'رمز عبور',
      'password_min_length_error': 'حداقل ۸ کاراکتر الزامیست',
      'login_button': 'ورود به حساب',
      'create_account_button': 'ایجاد حساب جدید',
      'login_toggle': 'ورود',
      'signup_toggle': 'ثبت‌نام',
      'unexpected_error': 'خطای نامشخص',
    },
  };

  static String getString(String key, bool isPersian) {
    final lang = isPersian ? 'fa' : 'en';
    return _localizedValues[lang]?[key] ?? key;
  }
}
