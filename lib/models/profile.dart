import '../core/constants/user_role.dart';

/// Профиль пользователя — расширение стандартной таблицы auth.users
/// Supabase дополнительными полями (имя, телефон, роль, заведение).
class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final String? establishmentId;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.role,
    required this.createdAt,
    this.fullName,
    this.phone,
    this.establishmentId,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: UserRoleX.fromValue(json['role'] as String),
      establishmentId: json['establishment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
