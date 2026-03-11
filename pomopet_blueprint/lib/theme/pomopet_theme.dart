import 'package:flutter/material.dart';

class PomopetTheme {
  static const tomato = Color(0xFFFF4D3A);
  static const tomatoDeep = Color(0xFFE63B2B);
  static const sky = Color(0xFF4DA3FF);
  static const skyDeep = Color(0xFF2E7FE3);
  static const gold = Color(0xFFFFC857);

  static const text = Color(0xFF1F2937);
  static const subText = Color(0xFF6B7280);

  static ThemeData byId(String themeId) {
    switch (themeId) {
      case 'fresh_blue':
        return _build(
          primary: sky,
          primaryDeep: skyDeep,
          secondary: tomato,
          bg: const Color(0xFFF3F8FF),
          card: Colors.white,
          border: const Color(0xFFD9E7FA),
          track: const Color(0xFFD9EBFF),
        );
      case 'tomato_strong':
      default:
        return _build(
          primary: tomato,
          primaryDeep: tomatoDeep,
          secondary: sky,
          bg: const Color(0xFFFFF7F3),
          card: Colors.white,
          border: const Color(0xFFEDE2DC),
          track: const Color(0xFFFFE2DD),
        );
    }
  }

  static ThemeData light() => byId('tomato_strong');

  static ThemeData _build({
    required Color primary,
    required Color primaryDeep,
    required Color secondary,
    required Color bg,
    required Color card,
    required Color border,
    required Color track,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: card,
      brightness: Brightness.light,
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
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(primaryDeep.withOpacity(0.12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
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
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: track,
      ),
    );
  }
}
