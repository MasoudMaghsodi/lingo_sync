import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_failure.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isObscure = true;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidName(String name) =>
      RegExp(r"^[a-zA-Z\s\u0600-\u06FF]+$").hasMatch(name);

  String _describeFailure(AuthFailure failure, bool isPersian) {
    switch (failure.reason) {
      case AuthFailureReason.invalidCredentials:
        return isPersian
            ? 'ایمیل یا رمز عبور اشتباه است.'
            : 'Invalid email or password.';
      case AuthFailureReason.emailInUse:
        return isPersian
            ? 'این ایمیل قبلاً ثبت‌نام کرده است.'
            : 'This email is already registered.';
      case AuthFailureReason.weakPassword:
        return isPersian ? 'رمز عبور ضعیف است.' : 'Password is too weak.';
      case AuthFailureReason.network:
        return isPersian
            ? 'خطا در ارتباط با سرور. دوباره تلاش کنید.'
            : 'Network error. Please try again.';
      case AuthFailureReason.unknown:
        return isPersian
            ? 'خطای نامشخصی رخ داد.'
            : 'An unknown error occurred.';
    }
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final repo = ref.read(authRepositoryProvider);
    final result = _isLoginMode
        ? await repo.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
        : await repo.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _nameController.text.trim(),
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final isPersian = ref.read(isPersianProvider);
    result.match(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_describeFailure(failure, isPersian)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (_) {
        // Nothing else to do here — AuthController is listening to the
        // auth stream and will move the app to the right screen on its
        // own the moment Supabase confirms the session.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPersian = ref.watch(isPersianProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: theme.colorScheme.primary,
            ),
            onPressed: () =>
                ref.read(isDarkModeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            color: theme.colorScheme.primary,
            onPressed: () =>
                ref.read(isPersianProvider.notifier).toggleLanguage(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 16),
                  child: child,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroBadge(color: theme.colorScheme.primary),
                  const SizedBox(height: 18),
                  Text(
                    'LingoSync',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPersian
                        ? 'بهترین مسیر تسلط بر زبان'
                        : 'The Ultimate Path to Fluency',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AuthModeToggle(
                            isLoginMode: _isLoginMode,
                            isPersian: isPersian,
                            theme: theme,
                            onChanged: (loginMode) {
                              if (loginMode == _isLoginMode) return;
                              _formKey.currentState?.reset();
                              setState(() => _isLoginMode = loginMode);
                            },
                          ),
                          const SizedBox(height: 18),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _isLoginMode
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: isPersian
                                            ? 'نام و نام خانوادگی'
                                            : 'Full Name',
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          color: theme.colorScheme.primary,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (_isLoginMode) return null;
                                        if (value == null ||
                                            value.trim().length < 3) {
                                          return isPersian
                                              ? 'نام باید حداقل ۳ حرف باشد'
                                              : 'Name must be at least 3 characters';
                                        }
                                        if (!_isValidName(value)) {
                                          return isPersian
                                              ? 'فقط حروف مجاز است'
                                              : 'Only letters allowed';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                          ),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: isPersian ? 'ایمیل' : 'Email',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  !RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(value)) {
                                return isPersian
                                    ? 'فرمت ایمیل نامعتبر است'
                                    : 'Invalid email format';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isObscure,
                            decoration: InputDecoration(
                              labelText: isPersian ? 'رمز عبور' : 'Password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: theme.colorScheme.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => _isObscure = !_isObscure),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return isPersian
                                    ? 'حداقل ۸ کاراکتر الزامیست'
                                    : 'Min 8 characters required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _authenticate,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: theme.colorScheme.primary.withValues(
                                alpha: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isLoginMode
                                        ? (isPersian ? 'ورود به حساب' : 'Login')
                                        : (isPersian
                                              ? 'ایجاد حساب جدید'
                                              : 'Create Account'),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==== Reusable pieces ====

class _HeroBadge extends StatelessWidget {
  final Color color;
  const _HeroBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.22), Colors.transparent],
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: color, size: 30),
          ),
        ],
      ),
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  final bool isLoginMode;
  final bool isPersian;
  final ThemeData theme;
  final ValueChanged<bool> onChanged;

  const _AuthModeToggle({
    required this.isLoginMode,
    required this.isPersian,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // AlignmentDirectional resolves automatically for RTL/LTR, so
          // this slides to the correct side regardless of app language.
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: isLoginMode
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ToggleLabel(
                  text: isPersian ? 'ورود' : 'Login',
                  active: isLoginMode,
                  onTap: () => onChanged(true),
                ),
              ),
              Expanded(
                child: _ToggleLabel(
                  text: isPersian ? 'ثبت‌نام' : 'Sign up',
                  active: !isLoginMode,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleLabel extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _ToggleLabel({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: active
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
