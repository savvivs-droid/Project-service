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

  /// Регистрация нового пользователя по коду приглашения.
  ///
  /// Роль и заведение пользователя мы НЕ передаём с клиента — их
  /// определяет сама база данных на основе кода приглашения (см.
  /// триггер handle_new_user в supabase/schema.sql). Так пользователь
  /// не может просто выбрать себе роль "администратор" в интерфейсе —
  /// без действительного кода с этой ролью учётная запись не будет
  /// привязана ни к какой роли и ни к какому заведению.
  Future<AuthResponse> signUpWithInviteCode({
    required String email,
    required String password,
    required String inviteCode,
    required String fullName,
    required String phone,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'invite_code': inviteCode.trim(),
        'full_name': fullName.trim(),
        'phone': phone.trim(),
      },
    );
  }

  /// Самостоятельная регистрация клиента без кода приглашения: клиент
  /// заводит своё заведение прямо при регистрации. Роль всегда 'client' —
  /// это решает база данных (см. handle_new_user), а не выбор в интерфейсе.
  /// Доступно только для роли "клиент": сотрудников (диспетчер/админ)
  /// по-прежнему заводит только по коду приглашения, см. [signUpWithInviteCode].
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
