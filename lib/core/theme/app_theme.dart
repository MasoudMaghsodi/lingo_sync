import 'package:flutter/material.dart';

class AppTheme {
  // پالت پرمیوم لایت‌مود (طلایی لوکس مات + پس‌زمینه عاجی ضد استرس چشم)
  static const Color goldPrimary = Color(0xFFC5A059);
  static const Color goldAccent = Color(0xFF9E7E38);
  static const Color bgLight = Color(0xFFFDFBF7); // Warm Ivory / Soft Alabaster
  static const Color surfaceLight = Colors.white;

  // پالت پرمیوم دارک‌مود (طلایی درخشان + خاکستری تیره یشمی محافظ چشم)
  static const Color goldDark = Color(0xFFE5C158);
  static const Color bgDark = Color(0xFF1E2525); // Deep Slate Jade
  static const Color surfaceDark = Color(0xFF283232);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: goldPrimary,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: goldPrimary,
        secondary: goldAccent,
        surface: surfaceLight,
        error: Color(0xFFBA1A1A),
      ),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        labelStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: goldDark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: goldDark,
        secondary: goldDark,
        surface: surfaceDark,
        error: Color(0xFFFFB4AB),
      ),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
      ),
    );
  }
}
