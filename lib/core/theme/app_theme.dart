import 'package:flutter/material.dart';

/// افزونه اختصاصی تم (ThemeExtension) برای رنگ‌هایی که در ColorScheme استاندارد جا نمی‌شوند.
/// این روش باعث می‌شود سوئیچ بین تم دارک و لایت کاملاً انیمیشن‌دار (Smooth) و تایپ‌سیف باشد.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color mutedBorder;
  final Color
  aiHighlight; // رنگ اختصاصی برای بک‌گراند یا هاله بخش‌های هوش مصنوعی
  final Color success; // رنگ موفقیت (برای اسنک‌بارها یا تیک‌ها)

  const AppColorsExtension({
    required this.mutedBorder,
    required this.aiHighlight,
    required this.success,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? mutedBorder,
    Color? aiHighlight,
    Color? success,
  }) {
    return AppColorsExtension(
      mutedBorder: mutedBorder ?? this.mutedBorder,
      aiHighlight: aiHighlight ?? this.aiHighlight,
      success: success ?? this.success,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      mutedBorder: Color.lerp(mutedBorder, other.mutedBorder, t)!,
      aiHighlight: Color.lerp(aiHighlight, other.aiHighlight, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

/// سیستم طراحی مرکزی اپلیکیشن (Design System)
class AppTheme {
  // پالت پرمیوم لایت‌مود
  static const Color goldPrimary = Color(0xFFC5A059);
  static const Color goldAccent = Color(0xFF9E7E38);
  static const Color bgLight = Color(0xFFFDFBF7);
  static const Color surfaceLight = Colors.white;

  // پالت پرمیوم دارک‌مود
  static const Color goldDark = Color(0xFFE5C158);
  static const Color bgDark = Color(0xFF1E2525);
  static const Color surfaceDark = Color(0xFF283232);

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    primary: goldPrimary,
    secondary: goldAccent,
    background: bgLight,
    surface: surfaceLight,
    error: const Color(0xFFBA1A1A),
    onSurface: Colors.black87,
    mutedBorder: Colors.grey.shade300,
    aiHighlight: const Color(0xFFF0F4F8), // رنگ ملایم برای لایت‌مود
    success: const Color(0xFF2E7D32),
  );

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    primary: goldDark,
    secondary: goldDark,
    background: bgDark,
    surface: surfaceDark,
    error: const Color(0xFFFFB4AB),
    onSurface: Colors.white,
    mutedBorder: Colors.grey.shade800,
    aiHighlight: const Color(0xFF1A2327), // رنگ تیره برای دارک‌مود
    success: const Color(0xFF81C784),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color error,
    required Color onSurface,
    required Color mutedBorder,
    required Color aiHighlight,
    required Color success,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: Colors.white,
    );

    final appColorsExtension = AppColorsExtension(
      mutedBorder: mutedBorder,
      aiHighlight: aiHighlight,
      success: success,
    );

    final baseBorderRadius = BorderRadius.circular(16);

    OutlineInputBorder inputBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: baseBorderRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      useMaterial3: true,
      extensions: [appColorsExtension], // تزریق اکستنشن به سیستم
      textTheme: _buildTextTheme(onSurface),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: primary),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: baseBorderRadius),
      ),

      dividerTheme: DividerThemeData(
        color: onSurface.withValues(alpha: 0.08),
        thickness: 1,
        space: 24,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: baseBorderRadius),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : onSurface.withValues(alpha: 0.55),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : onSurface.withValues(alpha: 0.55),
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.18),
        disabledColor: surface,
        labelStyle: TextStyle(color: onSurface, fontSize: 13),
        secondaryLabelStyle: TextStyle(color: primary, fontSize: 13),
        side: BorderSide(color: mutedBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.4)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: inputBorder(mutedBorder),
        enabledBorder: inputBorder(mutedBorder),
        focusedBorder: inputBorder(primary, width: 2),
        errorBorder: inputBorder(error),
        focusedErrorBorder: inputBorder(error, width: 2),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color onSurface) {
    return TextTheme(
      headlineLarge: TextStyle(
        color: onSurface,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: onSurface,
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: onSurface, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: onSurface, fontSize: 14, height: 1.5),
      bodySmall: TextStyle(
        color: onSurface.withValues(alpha: 0.6),
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        color: onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
