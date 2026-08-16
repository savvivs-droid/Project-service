import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class DeviceTokenRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Регистрирует (или обновляет) токен устройства текущего пользователя —
  /// вызывается при входе и при каждом обновлении токена (FCM время от
  /// времени ротирует токены сам). См. device_tokens в supabase/schema.sql.
  Future<void> upsert({required String token, required String platform}) {
    final profileId = _client.auth.currentUser!.id;
    return _client.from('device_tokens').upsert({
      'token': token,
      'profile_id': profileId,
      'platform': platform,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Убирает токен этого устройства при выходе — иначе после выхода
  /// один пользователь мог бы получать пуши, адресованные другому,
  /// если это устройство потом залогинят под другим аккаунтом.
  Future<void> remove(String token) {
    return _client.from('device_tokens').delete().eq('token', token);
  }
}
