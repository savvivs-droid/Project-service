import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

/// Тонкая обёртка над инициализацией пакета supabase_flutter.
class SupabaseService {
  static Future<void> initialize() {
    return Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      // PKCE (умолчание) требует code_verifier, сохранённый локально тем
      // же браузером/контекстом, что вызвал resetPasswordForEmail. Письмо
      // же обычно открывают из почтового приложения в другом контексте
      // (например, обычный Safari вместо иконки на экране Домой) — там
      // verifier недоступен, обмен кода на сессию молча падает, и вместо
      // формы нового пароля показывается обычный вход. Implicit flow
      // кладёт токены прямо в ссылку — сессия восстанавливается в любом
      // браузере без сохранённого состояния.
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
