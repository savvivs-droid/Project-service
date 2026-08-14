import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_locale_code';

/// Язык, выбранный вручную в приложении (переопределяет системный).
/// `value == null` значит "как в системе" — обычное автоматическое
/// поведение Flutter (см. supportedLocales в main.dart).
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController() : super(null);

  static const supportedLocales = [
    Locale('cs'),
    Locale('en'),
    Locale('ru'),
    Locale('vi'),
  ];

  /// Подтягивает сохранённый выбор при старте приложения — вызывается
  /// один раз в main() до runApp.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;
    value = supportedLocales.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => supportedLocales.first,
    );
  }

  Future<void> setLocale(Locale? locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}

/// Единственный экземпляр на всё приложение — простое глобальное
/// состояние для настройки, которая не завязана на конкретный экран.
final localeController = LocaleController();
