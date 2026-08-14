import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'supabase_service.dart';

class ProfileRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Возвращает профиль текущего авторизованного пользователя или null,
  /// если профиль ещё не создан (например, регистрация не завершена).
  Future<Profile?> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  /// Клиент может менять только своё имя и телефон — роль и заведение
  /// защищены RLS-триггером (см. schema.sql, trg_protect_profile_privileges).
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) {
    final userId = _client.auth.currentUser!.id;
    return _client.from('profiles').update({
      'full_name': fullName,
      'phone': phone,
    }).eq('id', userId);
  }
}
