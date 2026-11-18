import 'dart:convert';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_urls.dart';
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

  /// Отправляет письмо со ссылкой восстановления пароля. Supabase не
  /// сообщает, существует ли такой email — ошибку он вернёт только на
  /// сетевые/конфигурационные проблемы, что и позволяет не раскрывать
  /// в интерфейсе, зарегистрирован ли адрес. redirectTo должен быть
  /// заранее добавлен в Supabase Dashboard -> Authentication -> URL
  /// Configuration -> Redirect URLs.
  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(email, redirectTo: kAppWebUrl);
  }

  /// Смена email — в зависимости от настроек проекта (Authentication ->
  /// Sign In / Providers -> Email -> "Secure email change") Supabase
  /// может потребовать подтверждения по ссылке из письма, прежде чем
  /// адрес реально поменяется.
  Future<void> updateEmail(String newEmail) {
    return _client.auth.updateUser(UserAttributes(email: newEmail));
  }

  Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Самостоятельное удаление аккаунта клиентом. Обезличивает профиль
  /// (имя/телефон) и убирает доступ к заведениям на стороне базы (см.
  /// delete_own_account в supabase/schema.sql — история заявок
  /// сохраняется для бухгалтерского учёта сервисной компании), затем
  /// блокирует вход паролем из случайных символов, который здесь же и
  /// теряется, и завершает сессию. Полноценное удаление auth.users
  /// отсюда невозможно — на профиль ссылаются заявки клиента
  /// (on delete restrict), а обойти это можно только сервисным ключом
  /// вне доступа обычного пользователя приложения.
  Future<void> deleteOwnAccount() async {
    await _client.rpc('delete_own_account');

    final randomBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    await updatePassword(base64Url.encode(randomBytes));

    await signOut();
  }
}
