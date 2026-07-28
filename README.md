<div align="center">
  <img src="https://img.icons8.com/color/120/000000/language.png" alt="LingoSync Logo">
  <h1>LingoSync</h1>
  <p><b>Your Enterprise-Grade, AI-Powered Language Mentor</b></p>

  [![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
  [![Architecture](https://img.shields.io/badge/Architecture-Clean-success.svg)](ARCHITECTURE.md)
  [![State Management](https://img.shields.io/badge/State-Riverpod-orange.svg)](https://riverpod.dev/)
  [![Backend](https://img.shields.io/badge/Backend-Node.js-green.svg)](#)
  [![Database](https://img.shields.io/badge/BaaS-Supabase-3ECF8E.svg)](https://supabase.com/)
  [![AI Engine](https://img.shields.io/badge/AI-Google%20Gemini%20Live-purple.svg)](https://deepmind.google/technologies/gemini/)
  [![CI](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-blue.svg)](.github/workflows/flutter_ci.yml)
</div>

[🇺🇸 English](#english) | [🇮🇷 فارسی](#فارسی)

---

<a name="english"></a>
## 🇺🇸 English

**LingoSync** is a production-grade, offline-first language learning platform built around a real-time, voice-based AI mentor. A **Flutter** client following strict Clean Architecture communicates with a **Node.js** backend that proxies live audio sessions to the **Google Gemini Live API**, alongside a dedicated AI dictionary/analysis service.

### 🚀 Key Features

- 🤖 **Live AI Mentor** — Real-time, bidirectional voice conversations over WebSockets, proxied through a dedicated `mentor-server.js`, with audio streams offloaded to background isolates to keep the UI at 60fps.
- 📺 **Smart Video Analysis** — Paste any YouTube link to extract transcript translations, grammar breakdowns, and CEFR-leveled vocabulary via `ai-server.js`.
- 🧠 **Spaced Repetition Flashcards** — Offline-first flashcard system that queues reviews locally and syncs to the backend once connectivity returns.
- ⏱️ **Floating Pomodoro Timer** — A persistent, draggable focus timer available across every screen in the app.
- 🏆 **Live Leaderboard & Streaks** — Gamified daily tasks with real-time leaderboard updates.
- 🌓 **Full i18n & Theming** — Material 3 design with instant Light/Dark and English/Persian switching.
- ✅ **Tested & Automated** — Unit/widget tests under `test/`, with continuous integration via GitHub Actions (`.github/workflows/flutter_ci.yml`).

### 🛠️ Tech Stack

- **Frontend:** Flutter, Riverpod, Hive (offline caching)
- **Database & BaaS:** Supabase (PostgreSQL, Auth, Realtime, RPCs, RLS)
- **AI & Middleware Server:** Node.js, WebSockets, Docker
- **LLM Engine:** Google Gemini Live API

### 📁 Repository Layout

This is a monorepo containing the Flutter client, the Node.js backend, tests, and CI configuration side by side:

```text
lingo_sync/
├── lib/                    # Flutter client (see ARCHITECTURE.md)
├── backend/                # Node.js servers
│   ├── server.js           # Main API/auth server
│   ├── ai-server.js        # Dictionary & video analysis AI service
│   ├── mentor-server.js    # Real-time WebSocket proxy to Gemini Live
│   ├── docker-compose.yml
│   └── package.json
├── test/                   # Unit & widget tests (mirrors lib/ structure)
│   ├── core/
│   └── features/
├── .github/workflows/      # CI/CD pipeline (flutter_ci.yml)
├── pubspec.yaml
└── ARCHITECTURE.md
```

### ⚙️ Quick Start

**1. Clone the repository**
```bash
git clone https://github.com/MasoudMaghsodi/lingo_sync.git
cd lingo_sync
```

**2. Supabase setup**
- Create a project at [supabase.com](https://supabase.com).
- Apply your schema (tables, RLS policies, and RPC functions) to the project.

**3. Backend setup (Node.js)**

Create `backend/.env`:
```env
GEMINI_API_KEY=your_gemini_api_key
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_KEY=your_supabase_service_role_key
```

Then deploy:
```bash
cd backend
docker-compose up -d
```

**4. Flutter client setup**

Create a `.env` in the project root:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
AI_SERVER_BASE_URL=http://localhost:3002/api
MENTOR_SOCKET_URL=ws://localhost:3001
```

Then run:
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

**5. Run tests**
```bash
flutter test
```

> **Note:** the exact env var names, ports, and URLs above are placeholders matching this document's assumptions — swap in whatever your `app_config.dart` and backend actually read.

*For the full engineering breakdown of the codebase, see [ARCHITECTURE.md](ARCHITECTURE.md).*

---

<a name="فارسی"></a>
## 🇮🇷 فارسی

**LingoSync** یک پلتفرم حرفه‌ای و آفلاین‌محور برای یادگیری زبان است که حول محور یک **استاد هوش مصنوعی صوتی و بلادرنگ** ساخته شده. کلاینت **Flutter** با پایبندی کامل به Clean Architecture، از طریق یک بک‌اند **Node.js** با API زنده **Gemini Live** گوگل و همچنین یک سرویس اختصاصی برای تحلیل واژگان و ویدیو، ارتباط برقرار می‌کند.

### 🚀 ویژگی‌های کلیدی

- 🤖 **استاد هوش مصنوعی زنده** — مکالمه صوتی دوطرفه در لحظه از طریق WebSocket، با پروکسی اختصاصی `mentor-server.js` و پردازش صدا در نخ‌های پس‌زمینه برای حفظ روانی کامل UI.
- 📺 **تحلیل‌گر هوشمند ویدیو** — استخراج ترجمه زیرنویس، نکات گرامری و واژگان سطح‌بندی‌شده (CEFR) از هر لینک یوتیوب، از طریق `ai-server.js`.
- 🧠 **فلش‌کارت با تکرار فاصله‌دار** — سیستم آفلاین‌اول که مرورها را محلی ذخیره و پس از اتصال مجدد همگام‌سازی می‌کند.
- ⏱️ **تایمر پومودوروی شناور** — تایمر تمرکز شناور و قابل‌جابجایی در تمام صفحات اپ.
- 🏆 **لیدربورد و استریک زنده** — گیمیفیکیشن تسک‌های روزانه با به‌روزرسانی زنده امتیازات.
- 🌓 **پشتیبانی کامل دو زبانه و تم** — طراحی متریال ۳ با سوییچ آنی بین تاریک/روشن و فارسی/انگلیسی.
- ✅ **تست‌شده و خودکار** — تست‌های واحد و ویجت در `test/`، همراه با CI/CD از طریق GitHub Actions.

### 🛠️ پشته فناوری (Tech Stack)

- **فرانت‌اند:** Flutter، Riverpod، Hive (کش آفلاین)
- **دیتابیس و BaaS:** Supabase (PostgreSQL، Auth، Realtime، RPC، RLS)
- **سرور هوش مصنوعی و میان‌افزار:** Node.js، WebSocket، Docker
- **موتور LLM:** Google Gemini Live API

### 📁 ساختار مخزن

این پروژه یک Monorepo شامل کلاینت فلاتر، بک‌اند Node.js، تست‌ها و پیکربندی CI است (به بخش انگلیسی بالا برای درخت کامل پوشه‌ها مراجعه کنید).

### ⚙️ راه‌اندازی سریع

**۱. دریافت پروژه:**
```bash
git clone https://github.com/MasoudMaghsodi/lingo_sync.git
cd lingo_sync
```

**۲. راه‌اندازی Supabase:**
- یک پروژه در [supabase.com](https://supabase.com) بساز.
- اسکیمای خودت (جداول، قوانین RLS و توابع RPC) را روی آن اعمال کن.

**۳. راه‌اندازی بک‌اند (Node.js):**

فایل `backend/.env` را بساز:
```env
GEMINI_API_KEY=your_gemini_api_key
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_KEY=your_supabase_service_role_key
```

سپس اجرا کن:
```bash
cd backend
docker-compose up -d
```

**۴. راه‌اندازی کلاینت فلاتر:**

یک فایل `.env` در ریشه پروژه بساز:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
AI_SERVER_BASE_URL=http://localhost:3002/api
MENTOR_SOCKET_URL=ws://localhost:3001
```

سپس اجرا کن:
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

**۵. اجرای تست‌ها:**
```bash
flutter test
```

> **نکته:** نام دقیق متغیرهای محیطی، پورت‌ها و URLها بالا فقط فرضی هستند تا با ساختار همین سند هماهنگ باشند — آن‌ها را با چیزی که واقعاً در `app_config.dart` و بک‌اندت خوانده می‌شود جایگزین کن.

*برای جزئیات کامل مهندسی و معماری پروژه، به فایل [ARCHITECTURE.md](ARCHITECTURE.md) مراجعه کنید.*