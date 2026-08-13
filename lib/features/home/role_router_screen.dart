import 'package:flutter/material.dart';

import '../../core/constants/user_role.dart';
import '../../models/profile.dart';
import 'admin_home_screen.dart';
import 'client_home_screen.dart';

/// Показывает разный главный экран в зависимости от роли пользователя.
/// Это одно и то же приложение — просто разные разделы для разных ролей.
class RoleRouterScreen extends StatelessWidget {
  const RoleRouterScreen({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return switch (profile.role) {
      UserRole.client => ClientHomeScreen(profile: profile),
      UserRole.admin => AdminHomeScreen(profile: profile),
    };
  }
}
