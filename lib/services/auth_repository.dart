import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Работа с авторизацией Supabase Auth.
class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Регистрация клиента: клиент заводит своё заведение прямо при
  /// регистрации. Роль всегда 'client' — это решает база данных (см.
  /// handle_new_user в supabase/schema.sql), а не выбор в интерфейсе.
  /// Это единственный способ создать аккаунт через приложение —
  /// администраторов заводят вручную (см. schema.sql, раздел 7).
  Future<AuthResponse> signUpNewClient({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String establishmentIco,
    required String establishmentName,
    required String establishmentAddress,
    required String establishmentContactPhone,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'new_establishment_ico': establishmentIco.trim(),
        'new_establishment_name': establishmentName.trim(),
        'new_establishment_address': establishmentAddress.trim(),
        'new_establishment_contact_phone': establishmentContactPhone.trim(),
      },
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
