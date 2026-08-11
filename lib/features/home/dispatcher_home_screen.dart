import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/auth_repository.dart';

/// Заглушка главного экрана диспетчера.
/// На следующих этапах здесь появится список всех заявок по всем
/// заведениям с возможностью назначать время и статус.
class DispatcherHomeScreen extends StatelessWidget {
  const DispatcherHomeScreen({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Диспетчерская'),
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
            'Здравствуйте, ${profile.fullName ?? 'диспетчер'}!\n\n'
            'Здесь появится список всех заявок по всем заведениям.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
