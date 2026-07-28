# LingoSync — Architecture & Engineering Guide

[🇺🇸 English](#english) | [🇮🇷 فارسی](#فارسی)

---

<a name="english"></a>
## 🇺🇸 English

This document describes the actual, current architecture of the LingoSync codebase — both the Flutter client and the Node.js backend — and the engineering principles enforced across it.

### 1. Monorepo Layout

```text
lingo_sync/
├── lib/                       # Flutter client
├── backend/                   # Node.js services
│   ├── server.js
│   ├── ai-server.js
│   ├── mentor-server.js
│   ├── docker-compose.yml
│   └── package.json
├── test/                      # Mirrors lib/ structure
│   ├── core/
│   └── features/
└── .github/workflows/         # flutter_ci.yml
```

### 2. Backend Services (`backend/`)

The backend is split into three focused Node.js entry points rather than one monolith:

| File | Responsibility |
|---|---|
| `server.js` | Main API server — auth, profile, daily tasks, leaderboard |
| `ai-server.js` | Dictionary lookups, video transcript/grammar/vocabulary analysis |
| `mentor-server.js` | Real-time WebSocket proxy between the Flutter client and the Gemini Live API |
| `docker-compose.yml` | Orchestrates all services for local/production deployment |

Separating the mentor's WebSocket proxy from the REST API keeps the low-latency audio path isolated from ordinary CRUD traffic.

### 3. Flutter Client (`lib/`)

```text
lib/
├── main.dart
├── core/
│   ├── app/                   # app.dart — root widget & app-level wiring
│   ├── config/                # app_config.dart, app_bootstrap.dart
│   ├── constants/              # app / business / network / storage / ui constants
│   ├── exceptions/             # app_exceptions.dart — sealed AppException hierarchy
│   ├── extensions/             # build_context_extensions.dart
│   ├── layout/                 # main_navigation.dart
│   ├── localization/           # app_localizations.dart
│   ├── logging/                 # log_level, log_entry, app_logger
│   ├── providers/               # app_providers, app_shell_provider, settings_provider
│   ├── result/                  # result.dart — Result<T> wrapper
│   ├── services/                 # error_handler_service, tts_service
│   ├── theme/                    # app_theme.dart
│   ├── utils/                    # app_messenger.dart
│   └── widgets/                  # persian_content_text.dart
└── features/
    ├── auth/
    │   ├── application/           # auth_controller, auth_providers
    │   ├── data/                  # auth_repository, approval_repository
    │   ├── domain/                # auth_status.dart
    │   └── presentation/pages/    # login_page, auth_gate, awaiting_approval_page
    ├── ai_mentor/
    │   ├── data/models/           # mentor_state.dart
    │   ├── presentation/          # ai_mentor_controller, ai_mentor_sheet
    │   └── services/              # mentor_socket_service, mentor_audio_service
    ├── ai_dictionary/
    │   ├── data/
    │   │   ├── models/            # word_analysis, flashcard_entry, video_analysis
    │   │   ├── repositories/      # word, flashcard_sync, video_analysis repositories
    │   │   └── services/          # ai_server_client
    │   └── presentation/
    │       ├── pages/             # dictionary, flashcards, all_flashcards, all_grammar, video_lesson
    │       ├── providers/         # dictionary_provider, flashcards_provider
    │       └── widgets/           # archive/*, video_lesson/*
    ├── daily_tasks/
    │   ├── data/                  # daily_task_model, leaderboard_entry, daily_task_repository
    │   └── presentation/
    │       ├── pages/             # daily_tasks_page, leaderboard_page
    │       ├── providers/         # daily_tasks, leaderboard, pomodoro, selected_day
    │       └── widgets/           # floating_pomodoro, pomodoro_home_card
    └── settings/
        ├── data/                  # profile_repository
        └── presentation/
            ├── providers/         # profile_provider
            └── widgets/           # app_drawer
```

### 4. Feature Layering (Clean Architecture)

Every feature strictly follows: `data/ → (domain/) → presentation/`

- **`data/repositories`** — the *only* layer permitted to talk to the network, `Hive`, or `SharedPreferences`. UI code never touches storage or HTTP directly.
- **`data/models`** — immutable data classes with safe `fromJson`/`toJson` mappings.
- **`presentation/providers`** — Riverpod (`@riverpod`) controllers that orchestrate state; they call repositories, they never issue raw queries themselves.
- **`presentation/pages` & `widgets`** — purely declarative UI, no business logic.

`auth` additionally has an `application/` layer and a `domain/` layer (`auth_status.dart`) since its state machine (unauthenticated → pending approval → authenticated) is more complex than a typical feature.

### 5. Core Engineering Principles

1. **Typed error handling** — repositories never throw raw exceptions; they return `Future<Result<T>>` (`core/result/result.dart`). Failures are wrapped as `AppException` subtypes (`core/exceptions/app_exceptions.dart`) and translated to user-facing messages by `ErrorHandlerService`.
2. **Isolate-based audio processing** — `mentor_audio_service.dart` offloads `base64Encode`/`base64Decode` of PCM audio chunks to background isolates via `compute`, keeping the UI thread free during live mentor sessions.
3. **Cache-stampede protection** — `word_repository.dart` maintains an in-memory `_inflightRequests` lock so concurrent lookups of the same word collapse into a single backend call instead of flooding `ai-server.js`.
4. **Offline-first sync** — `flashcard_sync_repository.dart` queues review results locally and reconciles with the backend once connectivity is restored; `selected_day_provider` similarly caches the active timeline day via `SharedPreferences`.
5. **Realtime state** — `leaderboard_provider` and `daily_tasks_provider` stream live updates so gamification state (streaks, rankings) stays in sync without manual refresh.
6. **Logging** — a structured `AppLogger` with `LogLevel`/`LogEntry` types centralizes diagnostics across both client and backend boundaries.

### 6. BaaS & Database Architecture (Supabase)

Supabase is the core data layer of LingoSync, handling Auth, Database, Storage, and Realtime streams. The Node.js backend acts primarily as an AI proxy and background job runner on top of it.

- **Data schema** — normalized around a few key relationships:
  - `profiles` / `user_stats` — separates identity data from gamification metrics.
  - `daily_tasks` / `user_task_progress` — a many-to-many model tracking per-user task completion.
  - `global_dictionary` / `flashcards` — vocabulary and AI analyses are cached globally; individual users link to shared entries via `word_id` instead of duplicating data.
  - `video_analysis` — caches expensive Gemini results (transcripts, grammar, vocabulary) to avoid redundant AI calls for the same video.
- **RPCs** — gamification logic (e.g., score increments) runs as native PostgreSQL functions invoked via RPC, keeping updates atomic and race-free under concurrent writes.
- **Row Level Security (RLS)** — the Flutter client authenticates with the `anon` key and is restricted by RLS policies to its own rows. The Node.js backend uses the `service_role` key where it legitimately needs to bypass RLS (global dictionary writes, AI automation).
- **Auth verification over WebSocket** — the Flutter client passes its Supabase access token when opening the mentor WebSocket; `mentor-server.js` validates it against Supabase before starting an AI Mentor session, preventing identity spoofing on the audio channel.
- **Realtime** — leaderboard and streak updates are consumed directly from Supabase Realtime by `leaderboard_provider`, so rankings update live without polling.

> **Note:** table names, RPC names, and key usage above should be checked against your actual schema before publishing — keep this section accurate to what's really deployed rather than aspirational.

### 7. Testing & CI/CD

- `test/` mirrors the `lib/` structure (`test/core`, `test/features/ai_dictionary`, `test/features/daily_tasks`), covering exceptions, `Result`, and Pomodoro state logic.
- `.github/workflows/flutter_ci.yml` runs the automated pipeline (analyze, test, build) on every push/PR, so the `main` branch is always in a demonstrably working state.

---

<a name="فارسی"></a>
## 🇮🇷 فارسی

این سند معماری واقعی و فعلی پروژه LingoSync — هم کلاینت فلاتر و هم بک‌اند Node.js — و اصول مهندسی حاکم بر آن را شرح می‌دهد.

### ۱. ساختار Monorepo

به بخش انگلیسی بالا برای درخت کامل پوشه‌ها مراجعه کنید؛ ساختار شامل `lib/` (کلاینت)، `backend/` (سرورها)، `test/` (تست‌ها، هم‌ساختار با `lib/`) و `.github/workflows/` (پایپ‌لاین CI) است.

### ۲. سرویس‌های بک‌اند (`backend/`)

بک‌اند به‌جای یک سرور یکپارچه، به سه نقطه ورود مجزا تقسیم شده:

| فایل | مسئولیت |
|---|---|
| `server.js` | سرور اصلی API — احراز هویت، پروفایل، تسک‌های روزانه، لیدربورد |
| `ai-server.js` | جستجوی لغات و تحلیل ترجمه/گرامر/واژگان ویدیو |
| `mentor-server.js` | پروکسی WebSocket بلادرنگ بین کلاینت فلاتر و Gemini Live API |
| `docker-compose.yml` | راه‌اندازی یکپارچه تمام سرویس‌ها |

جدا کردن پروکسی صوتی استاد از API معمولی، مسیر حساس به تأخیر (Low-latency) صدا را از ترافیک عادی CRUD ایزوله نگه می‌دارد.

### ۳. کلاینت فلاتر (`lib/`)

ساختار کامل در بخش انگلیسی بالا آمده است: `core/` شامل تنظیمات، ثابت‌ها، خطاها، لاگینگ، پرووایدرهای سراسری، `Result<T>` و تم؛ و `features/` شامل پنج فیچر `auth`، `ai_mentor`، `ai_dictionary`، `daily_tasks` و `settings` است که هرکدام مستقل و ماژولار پیاده‌سازی شده‌اند.

### ۴. لایه‌بندی فیچرها (Clean Architecture)

هر فیچر دقیقاً از ساختار `data/ → (domain/) → presentation/` پیروی می‌کند:

- **`data/repositories`** — تنها لایه مجاز به ارتباط با شبکه، `Hive` یا `SharedPreferences`.
- **`data/models`** — مدل‌های تغییرناپذیر با مپینگ امن `fromJson`/`toJson`.
- **`presentation/providers`** — کنترلرهای Riverpod که فقط هماهنگ‌کننده وضعیت‌اند و مستقیماً کوئری اجرا نمی‌کنند.
- **`presentation/pages` و `widgets`** — صرفاً UI اعلانی، بدون منطق تجاری.

فیچر `auth` علاوه بر این، یک لایه `application/` و یک لایه `domain/` (`auth_status.dart`) دارد، چون ماشین وضعیتش (احراز نشده ← در انتظار تأیید ← احراز شده) پیچیده‌تر از فیچرهای دیگر است.

### ۵. اصول مهندسی هسته

۱. **مدیریت خطای Typed** — ریپازیتوری‌ها هرگز Exception خام پرتاب نمی‌کنند؛ `Future<Result<T>>` برمی‌گردانند و خطاها به‌صورت زیرکلاس‌های `AppException` کپسوله و توسط `ErrorHandlerService` برای کاربر ترجمه می‌شوند.
۲. **پردازش صدا در Isolate** — `mentor_audio_service.dart` عملیات `base64Encode`/`base64Decode` استریم صدای PCM را با `compute` به نخ‌های پس‌زمینه منتقل می‌کند تا UI در طول مکالمه زنده فریز نشود.
۳. **جلوگیری از Cache Stampede** — `word_repository.dart` با یک قفل درون‌حافظه‌ای (`_inflightRequests`) درخواست‌های همزمان یک لغت را در یک فراخوانی واحد ادغام می‌کند.
۴. **همگام‌سازی آفلاین‌اول** — `flashcard_sync_repository.dart` نتایج مرور را محلی صف‌بندی و پس از اتصال مجدد با بک‌اند همگام می‌کند؛ `selected_day_provider` نیز روز فعال تایم‌لاین را با `SharedPreferences` کش می‌کند.
۵. **وضعیت بلادرنگ** — `leaderboard_provider` و `daily_tasks_provider` به‌روزرسانی‌های زنده را استریم می‌کنند تا وضعیت گیمیفیکیشن بدون رفرش دستی همگام بماند.
۶. **لاگینگ** — یک `AppLogger` ساختاریافته با انواع `LogLevel`/`LogEntry` تشخیص خطا را در کلاینت و بک‌اند متمرکز می‌کند.

### ۶. معماری دیتابیس و سرویس‌ها (Supabase)

سوپابیس هسته اصلی داده‌های LingoSync است که مدیریت احراز هویت، دیتابیس، استوریج و استریم‌های Realtime را بر عهده دارد. بک‌اند Node.js بیشتر نقش پروکسی هوش مصنوعی و اجرای کارهای پس‌زمینه روی همین لایه را ایفا می‌کند.

- **اسکیمای دیتابیس** — نرمال‌سازی حول چند رابطه کلیدی:
  - `profiles` / `user_stats` — جداسازی اطلاعات هویتی از متریک‌های گیمیفیکیشن.
  - `daily_tasks` / `user_task_progress` — رابطه چند-به-چند برای ردیابی تکمیل تسک هر کاربر.
  - `global_dictionary` / `flashcards` — واژگان و تحلیل‌های هوش مصنوعی به‌صورت گلوبال کش می‌شوند؛ کاربران فقط از طریق `word_id` به رکورد مشترک متصل می‌شوند، نه تکرار داده.
  - `video_analysis` — کش کردن نتایج گران‌قیمت Gemini (ترجمه، گرامر، واژگان) برای جلوگیری از فراخوانی تکراری روی یک ویدیو.
- **توابع RPC** — منطق گیمیفیکیشن (مثل افزایش امتیاز) به‌صورت تابع بومی PostgreSQL و از طریق RPC اجرا می‌شود تا آپدیت‌ها اتمیک و بدون تداخل در نوشتن همزمان بمانند.
- **امنیت سطح ردیف (RLS)** — کلاینت فلاتر با کلید `anon` احراز هویت می‌شود و طبق قوانین RLS فقط به داده‌های خودش دسترسی دارد. بک‌اند Node.js از کلید `service_role` جایی استفاده می‌کند که واقعاً نیاز به دور زدن RLS دارد (نوشتن در دیکشنری گلوبال، اتوماسیون هوش مصنوعی).
- **تأیید هویت روی WebSocket** — کلاینت فلاتر توکن دسترسی Supabase خودش را هنگام باز کردن سوکت استاد ارسال می‌کند؛ `mentor-server.js` قبل از شروع نشست AI Mentor این توکن را نزد Supabase اعتبارسنجی می‌کند تا از جعل هویت روی کانال صوتی جلوگیری شود.
- **Realtime** — به‌روزرسانی‌های لیدربورد و استریک مستقیماً از Supabase Realtime توسط `leaderboard_provider` دریافت می‌شوند، بدون نیاز به Polling دستی.

> **نکته:** نام جداول، RPCها و نحوه استفاده از کلیدها را قبل از انتشار با اسکیمای واقعی پروژه‌ات تطبیق بده — این بخش باید منعکس‌کننده چیزی باشد که واقعاً دیپلوی شده، نه یک حالت آرمانی.

### ۷. تست و CI/CD

- پوشه `test/` هم‌ساختار با `lib/` است (`test/core`، `test/features/ai_dictionary`، `test/features/daily_tasks`) و منطق `Exception`ها، `Result` و وضعیت پومودورو را پوشش می‌دهد.
- `.github/workflows/flutter_ci.yml` پایپ‌لاین خودکار (آنالیز، تست، بیلد) را روی هر push/PR اجرا می‌کند تا شاخه `main` همیشه در وضعیت قابل‌اثبات سالم باقی بماند.