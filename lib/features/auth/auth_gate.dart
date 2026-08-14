import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../models/profile.dart';
import '../../services/auth_repository.dart';
import '../../services/profile_repository.dart';
import '../home/role_router_screen.dart';
import 'login_screen.dart';

/// Корневой виджет: слушает состояние авторизации Supabase и показывает
/// либо экран входа, либо (если пользователь вошёл) главный экран,
/// подобранный по роли из его профиля.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authRepository = AuthRepository();
  final _profileRepository = ProfileRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authRepository.authStateChanges,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        return FutureBuilder<Profile?>(
          // Ключ пересоздаёт FutureBuilder при каждой смене пользователя,
          // чтобы не показывать профиль предыдущего аккаунта.
          key: ValueKey(session.user.id),
          future: _profileRepository.fetchCurrentProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.authGateProfileNotFound,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _authRepository.signOut(),
                          child: Text(context.l10n.authGateSignOutRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return RoleRouterScreen(profile: profile);
          },
        );
      },
    );
  }
}
