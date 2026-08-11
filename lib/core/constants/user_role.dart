/// Роль пользователя в приложении.
///
/// Значения совпадают с значениями enum user_role в базе данных
/// (см. supabase/schema.sql), поэтому не переименовывайте value без
/// синхронного изменения схемы БД.
enum UserRole { client, dispatcher, admin }

extension UserRoleX on UserRole {
  String get value => switch (this) {
        UserRole.client => 'client',
        UserRole.dispatcher => 'dispatcher',
        UserRole.admin => 'admin',
      };

  String get label => switch (this) {
        UserRole.client => 'Клиент',
        UserRole.dispatcher => 'Диспетчер',
        UserRole.admin => 'Администратор',
      };

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.client,
    );
  }
}
