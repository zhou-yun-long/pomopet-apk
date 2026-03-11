import 'package:flutter/material.dart';

class PomopetTheme {
  // Tomato-strong palette v1
  static const tomato = Color(0xFFFF4D3A);
  static const tomatoDeep = Color(0xFFE63B2B);
  static const sky = Color(0xFF4DA3FF);
  static const gold = Color(0xFFFFC857);

  static const bg = Color(0xFFFFF7F3);
  static const card = Color(0xFFFFFFFF);

  static const text = Color(0xFF1F2937);
  static const subText = Color(0xFF6B7280);
  static const border = Color(0xFFEDE2DC);

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: tomato,
      onPrimary: Colors.white,
      secondary: sky,
      onSecondary: Colors.white,
      error: const Color(0xFFE11D48),
      onError: Colors.white,
      surface: card,
      onSurface: text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: subText),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tomato,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(tomatoDeep.withOpacity(0.12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tomato,
          side: const BorderSide(color: tomato, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: const TextStyle(color: subText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: tomato, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: tomato,
        linearTrackColor: Color(0xFFFFE2DD),
      ),
    );
  }
}
