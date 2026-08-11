import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/auth_repository.dart';

/// Заглушка главного экрана клиента.
/// На следующих этапах здесь появится список оборудования заведения
/// и заявок на ремонт.
class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моё заведение'),
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
            'Здравствуйте, ${profile.fullName ?? 'клиент'}!\n\n'
            'Здесь появится список оборудования и заявок вашего заведения.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
