/// Роль пользователя в приложении.
///
/// Значения совпадают с значениями enum user_role в базе данных
/// (см. supabase/schema.sql), поэтому не переименовывайте value без
/// синхронного изменения схемы БД.
///
/// Роли всего две: клиент регистрируется сам через приложение, админ
/// заводится вручную сотрудниками сервисной компании (см. schema.sql,
/// раздел 7) и обрабатывает все заявки — отдельной роли диспетчера нет.
enum UserRole { client, admin }

extension UserRoleX on UserRole {
  String get value => switch (this) {
        UserRole.client => 'client',
        UserRole.admin => 'admin',
      };

  String get label => switch (this) {
        UserRole.client => 'Клиент',
        UserRole.admin => 'Администратор',
      };

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.client,
    );
  }
}
