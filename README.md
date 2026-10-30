<div align="center">
  <img src="https://img.icons8.com/color/140/000000/language.png" alt="LingoSync Logo" width="100">
  <h1>LingoSync v2.0</h1>
  <p><b>Enterprise-Grade, Offline-First AI English Coach & IELTS/TOEFL Exam Twin</b></p>

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
  [![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20Offline--First-success.svg)](ARCHITECTURE.md)
  [![State Management](https://img.shields.io/badge/State-Riverpod%203-blueviolet.svg)](https://riverpod.dev/)
  [![Backend](https://img.shields.io/badge/Backend-Node.js%2022%20%7C%20Docker-339933?logo=node.js&logoColor=white)](#)
  [![Database](https://img.shields.io/badge/BaaS-Supabase%20Postgres-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com/)
  [![Live AI](https://img.shields.io/badge/Voice%20AI-Gemini%203.8%20Live-8E75C2?logo=google&logoColor=white)](https://deepmind.google/technologies/gemini/)
  [![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](.github/workflows/flutter_ci.yml)
  [![Tests](https://img.shields.io/badge/Tests-93%20Passing-brightgreen.svg)](#)
</div>

<br>

[🇺🇸 English](#english) | [🇮🇷 فارسی](#فارسی)

---

<a name="english"></a>
## 🇺🇸 English

**LingoSync v2.0** is an intelligent, offline-first English learning platform specifically tailored for Persian-speaking learners preparing for **IELTS, TOEFL, and CEFR B1–C2 proficiency**. 

The client is built with **Flutter** following strict Clean Architecture and reactive state management with **Riverpod 3**. It pairs with a high-performance, containerized **Node.js** backend running on a hardened cloud VPS that proxies bidirectional low-latency audio to **Google Gemini 3.8 Live**, while managing educational video processing, spaced-repetition synchronization, and pedagogical intelligence.

---

### 🌟 Key Capabilities & Architecture Highlights

#### 🎙️ Real-Time Voice Intelligence & AI Mentor
* **Gemini 3.8 Live Voice**: Low-latency bidirectional PCM voice conversations over authenticated WebSockets.
* **3-Tier Context Injection**: Dynamically synthesizes (1) Today's mission, (2) Recent performance & due cards, and (3) Persistent learner identity within a strict 500–800 token budget.
* **Active Recall Raid**: Unprompted elicitation of due SRS vocabulary during live conversations.
* **Code-Switch Rescue**: Natural English substitution whenever Persian intrusions occur, without breaking conversational flow.
* **VAD & Session Guard**: Silence detection (10s pause, 30s disconnect), 14-minute warning, and 15-minute hard session cap.

#### 🎓 Exam Twin (IELTS & TOEFL Speaking Simulator)
* Real-time interview simulation evaluated strictly against the **4 official IELTS band criteria**:
  1. *Fluency & Coherence (FC)*
  2. *Lexical Resource (LR)*
  3. *Grammatical Range & Accuracy (GRA)*
  4. *Pronunciation Heuristic (P)*
* Evidence-based scoring: every criterion is backed by **verbatim quotes** from the candidate's transcript with constructive Persian feedback and mandatory educational disclaimers.

#### 🧬 Personal Error Genome & Error-Driven SRS
* Post-interaction linguistic analysis detecting Persian-English (L1) interferences (e.g., preposition misuse, copula redundancy, false friends).
* Automatic generation of remedial flashcards (Front: learner's wrong sentence; Back: native correction + Persian explanation).

#### 🎨 60-Second C1 Upgrade Studio
* Rewrites user answers into sophisticated C1 CEFR structures by weaving in **active SRS flashcard words** and advanced syntax (Negative Inversion, Cleft sentences, Participle clauses) alongside instant TTS shadowing.

#### 📦 Offline-First Outbox Synchronization
* Client-side cryptographic UUIDv4 generation without external package overhead.
* Append-only `srs_review_logs` with idempotent batch RPCs (`sync_srs_reviews`) ensuring zero data loss and clock-skew resistance.

#### 🛡️ Telemetry, Cost Safety & Server Hardening
* **Spend Circuit Breaker**: Hard \$1.50/day per-user AI cost limiter.
* **1-Core 1GB VPS Hardening**: Configured 1GB swapfile (`swappiness=15`), strict Docker memory quotas (`ai-express`: 140MB, `ai-mentor`: 110MB, `yt-api`: 80MB), V8 garbage collection limits (`--max-old-space-size`), and zero-CPU event loop timers.

---

### 📂 Repository Structure

```text
lingo_sync/
├── lib/
│   ├── core/                      # Global theme, config, sync outbox & UUID utils
│   │   ├── config/                # Environment config & bootstrap
│   │   ├── sync/                  # Offline-first OutboxSyncService
│   │   └── utils/                 # Pure Dart StreakCalculator & UuidGenerator
│   └── features/
│       ├── ai_dictionary/         # YouTube video intelligence, dictionary & SRS
│       ├── ai_mentor/             # Gemini 3.8 Live voice & AI mentor chat
│       ├── auth/                  # Supabase Auth & 60s adaptive placement test
│       ├── daily_tasks/           # 10-minute daily sync mission & Pomodoro timer
│       ├── error_genome/          # L1 error taxonomy & remedial card repository
│       ├── exam_twin/             # IELTS/TOEFL speaking evaluation & rubrics
│       ├── practice/              # 60-Second C1 Upgrade Studio
│       └── subscription/          # Subscription tiers & payment provider bridges
├── backend/                       # Node.js microservices (Docker containerized)
│   ├── ai-server.js               # REST API: C1 Studio, Error Genome, Exam Twin
│   ├── mentor-server.js           # Low-latency WebSocket proxy to Gemini 3.8 Live
│   ├── context-builder.js         # 3-Tier budgeted context assembler
│   ├── telemetry-service.js       # Dynamic pricing, cost calculator & spend breaker
│   ├── server.js                  # YouTube transcript extractor
│   └── docker-compose.yml         # Resource-bounded container definitions
├── supabase/
│   └── migrations/                # Versioned SQL migrations & RLS policies
├── test/                          # Comprehensive unit & widget test suite (93 tests)
└── docs/lingosync_v2/             # SPEC.md & PROGRESS.md execution logs
```

---

### ⚙️ Quick Start Guide

#### 1. Prerequisites
- **Flutter SDK** ^3.12.2 / Dart ^3.x
- **Node.js** 22+ & Docker Compose
- **Supabase** account & project
- **Google Gemini API** key

#### 2. Backend Setup
```bash
cd backend
cp .env.example .env
# Fill in GEMINI_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_KEY, YT_PROXY_SECRET_KEY
docker compose up -d
```

#### 3. Client Setup
Create `.env` in the root folder:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
AI_SERVER_BASE_URL=https://your-domain.com/lingosync-api
MENTOR_SOCKET_URL=wss://your-domain.com/ws
YT_PROXY_SECRET_KEY=your-shared-secret-key
```

Run dependencies & code generator:
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

#### 4. Verification & Testing
```bash
# Verify code formatting and static analysis
dart format --output=none --set-exit-if-changed .
flutter analyze

# Run complete test suite (93 passing tests)
flutter test
```

---

<a name="فارسی"></a>
## 🇮🇷 فارسی

**لینگو سینک (LingoSync v2.0)** یک پلتفرم جامع و مدرن برای یادگیری زبان انگلیسی است که به طور تخصصی برای زبان‌آموزان فارسی‌زبان با هدف موفقیت در **آزمون‌های بین‌المللی آیلتس (IELTS)، تافل (TOEFL) و سطوح پیشرفته CEFR (B1–C2)** بازطراحی و پیاده‌سازی شده است.

این پروژه بر اساس اصول معماری تمیز (Clean Architecture) در **Flutter** و مدیریت وضعیت ری‌اکتیو با **Riverpod 3** پیاده‌سازی شده و از طریق یک زیرساخت مقیاس‌پذیر و امن **Node.js/Docker** روی سرور ابری هلند، ارتباط صوتی بلادرنگ با **Google Gemini 3.8 Live** را فراهم می‌سازد.

---

### 🚀 قابلیت‌های کلیدی نسخه ۲.۰

#### 🎙️ استاد صوتی هوش مصنوعی زنده (Live Voice Mentor)
* **مهاجرت به Gemini 3.8 Live**: مکالمه دوطرفه صوتی با کمترین تاخیر (Low Latency) بر بستر پروتکل ایمن WebSocket.
* **تزریق ۳ لایه‌ای کانتکست (3-Tier Context)**: خلاصه هوشمند هدف امروز، کارت‌های نیازمند مرور و سوابق زبانی کاربر در قالبی فشرده (۵۰۰ تا ۸۰۰ توکن).
* **عملیات بازیابی فعال (Active Recall Raid)**: پرسش و هدایت غیرمستقیم مکالمه برای به‌کارگیری واژگان هدف روز توسط زبان‌آموز در حین صحبت.
* **نجات تغییر کد (Code-Switch Rescue)**: در صورت کاربرد کلمات فارسی در جمله، هوش مصنوعی بدون قطع کردن رشته کلام کاربر، معادل طبیعی انگلیسی آن را جایگزین می‌کند.
* **مدیریت سکوت و نشست (VAD)**: توقف خودکار با ۱۰ ثانیه سکوت، قطع اتصال پس از ۳۰ ثانیه عدم فعالیت، هشدار دقیقه ۱۴ و سقف دقیق ۱۵ دقیقه برای هر نشست.

#### 🎓 شبیه‌ساز رسمی مصاحبه آزمون (Exam Twin)
* شبیه‌سازی کامل مصاحبه آیلتس و تافل با نمره‌دهی دقیق در ۴ معیار رسمی:
  1. *روانی و انسجام کلام (Fluency & Coherence)*
  2. *دایره و تنوع واژگان (Lexical Resource)*
  3. *دقت و تنوع ساختارهای گرامری (Grammatical Range & Accuracy)*
  4. *وضوح و ادای تلفظ (Pronunciation Heuristic)*
* **استناد به شواهد متنی**: استخراج و نمایش نقل‌قول مستقیم (`verbatim quote`) از صحبت‌های داوطلب برای هر نمره همراه با سلب مسئولیت استاندارد آموزشی (L12 Disclaimer).

#### 🧬 ژنوم خطاهای زبان‌آموز (Personal Error Genome)
* تحلیل هوشمند خطاهای ساختاری و تداخل زبان مادری (فارسی به انگلیسی) مانند حروف اضافه نادرست (*depends to*) یا افعال ربطی اضافی (*I am agree*).
* صدور آنی فلش‌کارت‌های مرور اصلاحی در فولدر اختصاصی Error Genome.

#### 🎨 استودیو ارتقای ۶۰ ثانیه‌ای C1 (C1 Upgrade Studio)
* بازنویسی جملات ساده داوطلب به سطح آکادمیک C1 با حفظ ایده اصلی، بافتن لغات فلش‌کارت‌های فعال کاربر و ساختارهای گرامری پیشرفته (مانند وارونگی Inversion و جملات Cleft) به همراه تمرین شدووینگ صوتی (TTS).

#### 📦 همگام‌سازی آفلاین‌اول (Offline-First Outbox)
* ثبت مرور فلش‌کارت‌ها در حافظه محلی Hive با استفاده از شناسه‌های یکتای RFC 4122 v4 UUID.
* ارسال دسته‌ای و ایمن به سرور (Idempotent RPC) پس از برقراری اینترنت بدون کوچک‌ترین خطر ثبت تکراری یا اتلاف پیشرفت.

#### 🛡️ بهینه‌سازی منابع سخت‌افزاری و ایمنی هزینه
* **سوئیچ قطع اضطراری هزینه (Spend Circuit Breaker)**: سقف مصرف ۱.۵ دلار در روز برای هر کاربر جهت جلوگیری از جهش هزینه‌های API.
* **پایدارسازی سرور ۱ هسته و ۱ گیگ رم**: فعال‌سازی حافظه Swap، محدودسازی سقف مصرف رم داکر (کانتینرها زیر ۹۲ مگابایت)، بهینه‌سازی زباله‌روب V8 و تایمرهای Zero-CPU در سرور نود.

---

### 🧪 تست‌ها و اعتبارسنجی کیفیت

تمام ماژول‌های پروژه تحت پوشش آزمون‌های واحد، مدل‌ها و ویجت‌ها قرار دارند:

```bash
# اعتبارسنجی فرمت فایل‌های دارت
dart format --output=none --set-exit-if-changed .

# تحلیل استاتیک دارت بدون خطا و هشدار
flutter analyze

# اجرای ۹۳ آزمون واحد با نتیجه ۱۰۰٪ قبولی
flutter test
```

---

### 📄 مجوز و مستندات
* مستندات معماری تفصیلی سیستم: [ARCHITECTURE.md](ARCHITECTURE.md)
* گزارش فازبندی و سوابق تصمیم‌گیری: [docs/lingosync_v2/PROGRESS.md](docs/lingosync_v2/PROGRESS.md)
* سند مشخصات فنی فازهای ۲.۰: [docs/lingosync_v2/SPEC.md](docs/lingosync_v2/SPEC.md)
