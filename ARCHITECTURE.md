# LingoSync — Architecture Guide

این سند خلاصه‌ی معماری نهایی پروژه بعد از ریفکتور کامل (فازهای ۱ تا ۵) است. هدفش
این است که تصمیمات معماری این‌جا مستند بمانند تا در توسعه‌ی آینده دوباره تکرار
نشوند.

## ساختار پوشه‌ها

lib/
├── main.dart, app.dart, app_messenger.dart, main_navigations.dart
├── core/
│   ├── config/          # AppConfig — تنها نقطه‌ی خواندن .env
│   ├── constants/        # AppConstants — مقادیر ثابت UI/timing
│   ├── exceptions/        # AppException سیل‌شده — قرارداد واحد خطا
│   ├── result/            # Result<T> — wrapper موفقیت/شکست
│   ├── services/          # ErrorHandlerService, TtsService (سراسری، keepAlive)
│   ├── logging/            # AppLogger
│   ├── localization/        # AppLocalizations — تمام رشته‌های دوزبانه
│   ├── theme/                # AppTheme — تنها منبع رنگ/تایپوگرافی/شکل ویجت‌ها
│   ├── extensions/            # BuildContextExtensions
│   └── providers/               # Providerهای سراسری (settings, pomodoro)
└── features/
├── auth/          # data → domain → application → presentation
├── daily_tasks/
├── ai_dictionary/
└── ai_mentor/

هر فیچر لایه‌بندی `data/ → (domain/) → presentation/` را دنبال می‌کند:
- **data/repositories**: تنها لایه‌ای که مستقیم با Supabase/HTTP/Hive کار می‌کند.
- **data/models**: کلاس‌های `fromJson`/`toJson`.
- **presentation/providers**: پل بین ریپازیتوری و UI (Riverpod `@riverpod`).
- **presentation/pages, presentation/widgets**: فقط UI.

## قرارداد خطا (Error Handling)

- **هر متد ریپازیتوری که ممکن است شکست بخورد، `Future<Result<T>>` برمی‌گرداند**،
  نه throw خام و نه `Either<String, T>`.
- خطاها همیشه از نوع `AppException` (یا زیرکلاس‌های آن در
  `core/exceptions/app_exceptions.dart`) هستند.
- لایه‌ی provider با `result.getOrThrow()` نتیجه را باز می‌کند؛ این throw توسط
  `AsyncNotifier`/`@riverpod` گرفته و به `AsyncValue.error` تبدیل می‌شود.
- لایه‌ی UI هرگز پیام خطا را خودش نمی‌سازد؛ از
  `errorHandler.getUserMessage(exception)` استفاده می‌کند تا پیام یکدست و
  ترجمه‌شده باشد.
- درخواست‌های شبکه‌ای حساس (AI server) از `errorHandler.executeWithRetry`
  عبور می‌کنند تا خطاهای موقتی شبکه به‌طور خودکار retry شوند.

## قرارداد i18n

- **هیچ رشته‌ی UI جدیدی نباید مستقیم `isPersian ? '...' : '...'` نوشته شود.**
  همه‌ی رشته‌ها باید کلید جدید در `AppLocalizations._localizedValues` باشند و
  با `AppLocalizations.getString('key', isPersian)` خوانده شوند.
- استثنا: پیام‌های نگاشت‌شده از یک enum دامنه (مثل `AuthFailureReason` در
  `LoginPage._describeFailure`) که منطقاً یک "ترجمه‌ی enum" هستند، نه یک رشته‌ی
  آزاد — این‌ها هم باید در نهایت از `AppLocalizations` بخوانند.

## قرارداد Theme

- تمام رنگ، تایپوگرافی، و شکل ویجت‌های استاندارد (AppBar, Card, Chip, SnackBar,
  Button, Input) از `AppTheme` می‌آید. صفحات نباید دوباره `RoundedRectangleBorder`
  یا `TextStyle` پایه را برای این ویجت‌ها بازتعریف کنند مگر برای یک استثنای
  واقعاً خاص (مثل فلش‌کارت‌های رنگی یا پودیوم لیدربورد).
- مقادیر padding/radius/duration پرکاربرد باید از `AppConstants` بیایند.

## قرارداد Provider (Riverpod)

- همه‌ی providerهای جدید با `@riverpod` code-gen نوشته می‌شوند (نه
  `StateNotifierProvider`/`Provider` دستی)، مگر جایی که خودِ Riverpod چنین
  الگویی را برای یک منظور خاص تحمیل کند (مثل `leaderboard_page.dart` که چند
  Stream/Future را combine می‌کند).
- `keepAlive: true` فقط برای providerهایی که باید در کل عمر اپ زنده بمانند
  (Auth, Settings, Pomodoro, TtsService, repositoryهای سراسری) استفاده می‌شود.
- **هرگز `ref.read`/`ref.watch` داخل `dispose()` صدا زده نمی‌شود.** اگر یک
  سرویس/provider در `dispose()` لازم است، باید در `initState()` در یک فیلد
  `late final` کش شود (نمونه: `TtsService` در تمام صفحاتی که ازش استفاده
  می‌کنند).
- تب‌های داخل `IndexedStack` (در `MainNavigation`) به‌صورت lazy ساخته می‌شوند —
  فقط وقتی کاربر برای اولین بار به آن تب می‌رود، ویجت واقعی‌اش ساخته می‌شود؛ این
  از subscribe شدن زودهنگام به providerهای stream-محور (مثل لیدربورد) در حین
  build اولیه‌ی اپ جلوگیری می‌کند.

## Schema فلش‌کارت

هر ردیف جدید در جدول `flashcards` — چه از جستجوی لغت بیاید چه از ذخیره‌ی یک
نکته‌ی گرامری — همیشه از طریق `WordRepository.saveToPersonalFlashcards` ساخته
می‌شود و شکل یکسانی دارد: `word_id` که به `global_dictionary` اشاره می‌کند، به‌
همراه `folder_name` (`'General'` یا `'Grammar'` یا پوشه‌ی سفارشی کاربر). رکوردهای
قدیمی‌تر ممکن است شکل متفاوتی (`ai_analysis` inline بدون `word_id`) داشته باشند؛
به همین دلیل لایه‌ی نمایش (`FlashcardsPage`, `AllFlashcardsPage`) همچنان fallback
`globalDict['ai_analysis'] ?? card['ai_analysis']` را نگه می‌دارد.

## مسائل شناخته‌شده (Known Issues)

### 🔴 باز — رفتار ناپایدار Auth در استارتاپ سرد (cold start)
**علائم:** گاهی بلافاصله بعد از اجرای اپ، کاربر لاگ‌اوت می‌شود و/یا اپ متوقف
می‌شود؛ نیاز به hot reload دستی برای بازیابی. بعد از reload، گاهی با توکن
موجود خودکار لاگین می‌شود و گاهی باید دستی وارد شود.

**فرضیه‌ی فعلی:** race بین بازیابی/رفرش سشن Supabase از دیسک (که یک عملیات
شبکه‌ای async است) و آماده بودن شبکه‌ی دستگاه بلافاصله بعد از cold start؛ یک
شکست موقت شبکه در این رفرش می‌تواند به‌اشتباه به‌عنوان `signedOut` واقعی تفسیر
شود (`AuthController._onAuthEvent`)، چون در سطح event نمی‌توان "کاربر خودش خارج
شد" را از "رفرش توکن به‌خاطر شبکه fail شد" تشخیص داد.

**وضعیت:** در انتظار لاگ کامل (از launch تا کرش) برای تشخیص دقیق قبل از هر
تغییری در `AuthController` — به‌خاطر حساسیت این فایل برای کل مسیر ناوبری اپ،
تغییر بدون مدرک انجام نمی‌شود.

## تست‌ها

پوشه‌ی `test/` شامل تست‌های واحد برای منطق خالص (بدون نیاز به mock کردن
Supabase/پلتفرم) است: `Result`, `AppException`, `DailyTaskModel`,
`WordAnalysis`/`WordDetail`, و `PomodoroState`. تست‌های state machine‌های
وابسته به Supabase (`AuthController`) یا platform channel (`TtsService`) در
این فاز پوشش داده نشده‌اند چون نیازمند زیرساخت mock (مثل `mocktail` +
`fake_async`) هستند که در فاز جداگانه‌ای می‌تواند اضافه شود.