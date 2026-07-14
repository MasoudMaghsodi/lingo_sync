import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingo_sync/features/ai_mentor/presentation/widgets/ai_mentor_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'features/daily_tasks/presentation/pages/daily_tasks_page.dart';
import 'features/ai_dictionary/presentation/pages/dictionary_page.dart';
import 'features/ai_dictionary/presentation/pages/flashcards_page.dart';
import 'features/daily_tasks/presentation/pages/leaderboard_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
// ایمپورت ویجت داینامیک آیلند
import 'features/daily_tasks/presentation/widgets/floating_pomodoro.dart';

class LingoSyncApp extends ConsumerStatefulWidget {
  const LingoSyncApp({super.key});

  @override
  ConsumerState<LingoSyncApp> createState() => _LingoSyncAppState();
}

class _LingoSyncAppState extends ConsumerState<LingoSyncApp> {
  User? _currentUser;
  bool _isLoading = true;
  bool _isApproved = false;
  // یک متغیر برای مدیریت گوش دادن به استریم
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // اگر کاربر کلاً خارج شده بود
      if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _currentUser = null;
            _isApproved = false;
            _isLoading = false;
          });
        }
        return;
      }

      if (session != null) {
        _currentUser = session.user;

        // اگر این اولین بار است که اپ باز می‌شود، یا کاربر لاگین کرده، یا توکنش همین الان رفرش شده
        if (event == AuthChangeEvent.initialSession ||
            event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed) {
          // حل باگ Race Condition:
          // اگر اپلیکیشن تازه باز شده و توکن منقضی است، ریکوئست دیتابیس نمی‌زنیم!
          // صبر می‌کنیم تا سوپابیس رویداد 'tokenRefreshed' را بلافاصله بعدش بفرستد.
          if (event == AuthChangeEvent.initialSession && session.isExpired) {
            return;
          }

          // حالا که مطمئنیم توکن سالم است، وضعیت تایید ادمین را چک می‌کنیم
          await _fetchApprovalStatus();
        }
      } else {
        // اگر سشنی وجود نداشت
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _fetchApprovalStatus() async {
    if (_currentUser == null) return;
    try {
      final response = await Supabase.instance.client
          .from('user_stats')
          .select('is_approved')
          .eq('id', _currentUser!.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isApproved = response?['is_approved'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final isPersian = ref.watch(isPersianProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LingoSync',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Directionality(
        textDirection: isPersian ? TextDirection.rtl : TextDirection.ltr,
        child: _buildHome(isPersian, Theme.of(context)),
      ),
    );
  }

  Widget _buildHome(bool isPersian, ThemeData theme) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_currentUser == null) {
      return const LoginPage();
    }

    if (_isApproved) {
      return const MainNavigation();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('user_stats')
          .stream(primaryKey: ['id'])
          .eq('id', _currentUser!.id),
      builder: (context, snapshot) {
        bool liveApproval = false;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          liveApproval = snapshot.data!.first['is_approved'] ?? false;
        }

        if (liveApproval) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isApproved = true;
              });
            }
          });
          return const MainNavigation();
        }

        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPersian
                        ? 'در انتظار تایید ادمین'
                        : 'Awaiting Admin Approval',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPersian
                        ? 'حساب شما ساخته شد.\nبه محض تایید مدیریت، این صفحه به صورت خودکار باز خواهد شد.'
                        : 'Your account has been created.\nThis page will automatically refresh once the admin approves you.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 48),
                  TextButton.icon(
                    onPressed: () => Supabase.instance.client.auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: Text(isPersian ? 'خروج از حساب' : 'Logout'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});
  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    // DailyTasksPage(),
    // DictionaryPage(),
    // FlashcardsPage(),
    // LeaderboardPage(),
    DailyTasksPage(),
    DictionaryPage(),
    SizedBox.shrink(), // <--- این را برای جای خالی دکمه وسط اضافه کن
    FlashcardsPage(),
    LeaderboardPage(),
  ];

  // فراموش نکن فایل باتم‌شیت را در بالای app.dart ایمپورت کنی:
  // import 'features/ai_mentor/presentation/widgets/ai_mentor_sheet.dart';

  @override
  Widget build(BuildContext context) {
    final isPersian = ref.watch(isPersianProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          const FloatingPomodoro(),
        ],
      ),

      // =====================================
      // دکمه جادویی احضار استاد (AI Mentor)
      // =====================================
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AiMentorSheet(),
          );
        },
        child: Container(
          width: 65,
          height: 65,
          margin: const EdgeInsets.only(top: 30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, Colors.deepPurpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          // setState(() {
          //   _currentIndex = index;
          // });
          if (index == 2) {
            return; // جلوگیری از کرش وقتی روی فضای خالی وسط کلیک می‌شود
          }
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.check_box_outlined),
            label: isPersian ? 'تسک‌ها' : 'Tasks',
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: isPersian ? 'دیکشنری' : 'Dictionary',
          ),
          // فاصله‌گذار برای جا باز کردن دکمه شناور وسط
          const NavigationDestination(icon: SizedBox.shrink(), label: ''),
          NavigationDestination(
            icon: const Icon(Icons.style_outlined),
            label: isPersian ? 'مرور' : 'Review',
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            label: isPersian ? 'رتبه‌بندی' : 'Leaderboard',
          ),
        ],
      ),
    );
  }
}
