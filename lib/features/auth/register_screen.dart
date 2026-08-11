import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/user_role.dart';
import '../../services/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  // Выбор роли в интерфейсе — это только подсказка для пользователя
  // (меняет текст под полем "код приглашения"). Реальную роль назначает
  // сервер по коду приглашения, см. комментарий в auth_repository.dart.
  UserRole _selectedRole = UserRole.client;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await _authRepository.signUpWithInviteCode(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        inviteCode: _inviteCodeController.text,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
      );

      if (!mounted) return;

      if (response.session == null) {
        _showMessage(
          'Регистрация почти завершена! Подтвердите email по ссылке из '
          'письма, а затем войдите.',
        );
      }
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      _showMessage(_translateError(e.message));
    } catch (_) {
      _showMessage(
        'Не удалось зарегистрироваться. Проверьте код приглашения и '
        'подключение к интернету.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invite') || lower.contains('приглаш')) {
      return 'Код приглашения недействителен, уже использован или относится '
          'к другой роли.';
    }
    if (lower.contains('already registered') ||
        lower.contains('already exists')) {
      return 'Пользователь с таким email уже зарегистрирован.';
    }
    return message;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Кто вы?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<UserRole>(
                      segments: const [
                        ButtonSegment(
                          value: UserRole.client,
                          label: Text('Клиент'),
                          icon: Icon(Icons.storefront_outlined),
                        ),
                        ButtonSegment(
                          value: UserRole.dispatcher,
                          label: Text('Диспетчер'),
                          icon: Icon(Icons.support_agent_outlined),
                        ),
                        ButtonSegment(
                          value: UserRole.admin,
                          label: Text('Админ'),
                          icon: Icon(Icons.admin_panel_settings_outlined),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (selection) {
                        setState(() => _selectedRole = selection.first);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedRole == UserRole.client
                          ? 'Введите код приглашения, который выдала '
                              'сервисная компания — он привяжет вас к '
                              'вашему заведению.'
                          : 'Введите код приглашения сотрудника, выданный '
                              'администратором сервисной компании.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Имя'),
                      validator: (value) => (value == null ||
                              value.trim().isEmpty)
                          ? 'Введите имя'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Телефон'),
                      validator: (value) => (value == null ||
                              value.trim().isEmpty)
                          ? 'Введите телефон'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          (value == null || !value.contains('@'))
                              ? 'Введите корректный email'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Пароль'),
                      validator: (value) =>
                          (value == null || value.length < 6)
                              ? 'Минимум 6 символов'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _inviteCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Код приглашения',
                        hintText: 'Например, CAFE-4F2A',
                      ),
                      validator: (value) => (value == null ||
                              value.trim().isEmpty)
                          ? 'Код приглашения обязателен'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Зарегистрироваться'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
