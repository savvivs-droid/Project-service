import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

/// Тонкая обёртка над инициализацией пакета supabase_flutter.
class SupabaseService {
  static Future<void> initialize() {
    return Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
