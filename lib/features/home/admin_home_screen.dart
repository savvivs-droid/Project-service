import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/auth_repository.dart';

/// Заглушка главного экрана администратора.
/// На следующих этапах здесь появится управление заведениями,
/// сотрудниками и кодами приглашений.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Администрирование'),
        actions: [
          IconButton(
            onPressed: () => AuthRepository().signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Здравствуйте, ${profile.fullName ?? 'администратор'}!\n\n'
            'Здесь появится управление заведениями, сотрудниками и '
            'кодами приглашений.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
