import 'package:flutter/material.dart';

/// Цвета из FixMyGastro Brand Book 2026: Deep Teal — основной цвет
/// бренда (логотип, заголовки, формы), Service Orange — единственный
/// акцент (CTA, важные детали), Soft Grey — вторичный фон. Статусы
/// заявок (см. RequestStatus.color) — отдельная, служебная палитра.
class AppTheme {
  static const primary = Color(0xFF02445A); // Deep Teal
  static const accent = Color(0xFFF37012); // Service Orange
  static const background = Color(0xFFF5F7F8); // Soft Grey
  static const onPrimary = Color(0xFFFFFFFF); // Pure White

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(seedColor: primary).copyWith(secondary: accent);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      // Фирменный шрифт по Brand Book 2026 вместо системного
      // Roboto/San Francisco — см. assets/fonts (Montserrat, Google
      // Fonts, OFL-лицензия).
      fontFamily: 'Montserrat',
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      // Единый фирменный AppBar на всех экранах — deep teal с белым
      // текстом/иконками, как на иконке приложения, а не серо-белый
      // Material-стандарт.
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        titleTextStyle: TextStyle(
          color: onPrimary,
          fontFamily: 'Montserrat',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: onPrimary),
      ),
    );
  }
}
