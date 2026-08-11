import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Читает настройки подключения к Supabase из файла .env.
///
/// Мы не храним URL и ключ прямо в коде, чтобы их можно было менять
/// без пересборки приложения и не публиковать в git-репозитории.
class AppConfig {
  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Не найдена переменная окружения "$key". '
        'Скопируйте .env.example в .env и заполните значениями из '
        'Supabase Dashboard -> Project Settings -> API.',
      );
    }
    return value;
  }
}
