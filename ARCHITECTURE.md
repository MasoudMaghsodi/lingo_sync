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

### 6. Testing & CI/CD

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

### ۶. تست و CI/CD

- پوشه `test/` هم‌ساختار با `lib/` است (`test/core`، `test/features/ai_dictionary`، `test/features/daily_tasks`) و منطق `Exception`ها، `Result` و وضعیت پومودورو را پوشش می‌دهد.
- `.github/workflows/flutter_ci.yml` پایپ‌لاین خودکار (آنالیز، تست، بیلد) را روی هر push/PR اجرا می‌کند تا شاخه `main` همیشه در وضعیت قابل‌اثبات سالم باقی بماند.