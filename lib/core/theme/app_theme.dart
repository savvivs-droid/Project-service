import 'package:flutter/material.dart';

/// Цвета из дизайн-макета FixMyGastro: глубокий тёмно-бирюзовый (petrol) —
/// основной цвет бренда, вместо дежурного "сервисного синего"; рабочий
/// оранжевый (amber) — единственный акцент для CTA. Статусы заявок
/// (см. RequestStatus.color) — отдельная, служебная палитра.
class AppTheme {
  static const primary = Color(0xFF0E5C63);
  static const accent = Color(0xFFE2762B);
  static const background = Color(0xFFF3F6F5);
  static const onPrimary = Color(0xFFF3F6F5);

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(seedColor: primary).copyWith(secondary: accent);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      // Фирменный шрифт вместо системного Roboto/San Francisco —
      // см. assets/fonts (Golos Text, Google Fonts, OFL-лицензия).
      fontFamily: 'Golos Text',
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      // Единый фирменный AppBar на всех экранах — петроль с кремовым
      // текстом/иконками, как на иконке приложения, а не серо-белый
      // Material-стандарт.
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        titleTextStyle: TextStyle(
          color: onPrimary,
          fontFamily: 'Golos Text',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: onPrimary),
      ),
    );
  }
}
