import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../models/profile.dart';
import '../../services/auth_repository.dart';
import '../../services/profile_repository.dart';
import '../../services/push_notification_service.dart';
import '../home/role_router_screen.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

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

  // Ссылка из письма восстановления пароля открывает приложение с уже
  // установленной сессией — но зайти в неё как в обычный логин нельзя,
  // сперва нужно задать новый пароль. Флаг живёт до успешного
  // ResetPasswordScreen.onDone, после чего сессия используется как
  // обычная (второй раз логиниться не нужно).
  bool _isPasswordRecovery = false;
  StreamSubscription<AuthState>? _recoverySubscription;

  @override
  void initState() {
    super.initState();
    _recoverySubscription = _authRepository.authStateChanges.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery && mounted) {
        setState(() => _isPasswordRecovery = true);
      }
    });
  }

  @override
  void dispose() {
    _recoverySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authRepository.authStateChanges,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        if (_isPasswordRecovery) {
          return ResetPasswordScreen(
            onDone: () => setState(() => _isPasswordRecovery = false),
          );
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

            // Заводит/обновляет токен устройства для push-уведомлений —
            // не блокирует отрисовку экрана, ошибки (например, отказ в
            // разрешении) не критичны для работы приложения.
            unawaited(PushNotificationService.instance.registerForCurrentUser());

            return RoleRouterScreen(profile: profile);
          },
        );
      },
    );
  }
}
