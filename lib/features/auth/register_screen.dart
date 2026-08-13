import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/user_role.dart';
import '../../core/utils/ico_validator.dart';
import '../../services/ares_service.dart';
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
  final _icoController = TextEditingController();
  final _establishmentNameController = TextEditingController();
  final _establishmentAddressController = TextEditingController();
  final _establishmentPhoneController = TextEditingController();

  // Выбор роли в интерфейсе — это только подсказка для пользователя
  // (меняет текст и набор полей ниже). Реальную роль назначает сервер,
  // см. комментарий в auth_repository.dart.
  UserRole _selectedRole = UserRole.client;

  // Только для роли "клиент": можно зарегистрироваться по коду от
  // сервисной компании (привязка к уже существующему заведению) либо
  // без кода, заведя своё заведение самостоятельно. Сотрудники
  // (диспетчер/админ) всегда регистрируются только по коду.
  bool _hasInviteCode = false;

  bool _isLoading = false;

  Timer? _icoDebounce;
  bool _isLookingUpIco = false;
  String? _icoLookupNote;

  bool get _isClient => _selectedRole == UserRole.client;
  bool get _requiresInviteCode => !_isClient || _hasInviteCode;

  @override
  void dispose() {
    _icoDebounce?.cancel();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    _icoController.dispose();
    _establishmentNameController.dispose();
    _establishmentAddressController.dispose();
    _establishmentPhoneController.dispose();
    super.dispose();
  }

  void _onIcoChanged(String value) {
    _icoDebounce?.cancel();
    setState(() => _icoLookupNote = null);

    if (!isValidCzechIco(value)) return;

    _icoDebounce = Timer(const Duration(milliseconds: 500), () {
      _lookupIco(value.trim());
    });
  }

  Future<void> _lookupIco(String ico) async {
    setState(() => _isLookingUpIco = true);
    final company = await AresService.lookupByIco(ico);
    if (!mounted) return;

    setState(() {
      _isLookingUpIco = false;
      if (company == null) {
        _icoLookupNote =
            'Не нашли организацию в ARES — заполните название и адрес '
            'вручную.';
      } else {
        _establishmentNameController.text = company.name;
        if (company.address != null) {
          _establishmentAddressController.text = company.address!;
        }
        _icoLookupNote = 'Данные подтянуты из ARES.';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final AuthResponse response;
      if (_requiresInviteCode) {
        response = await _authRepository.signUpWithInviteCode(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          inviteCode: _inviteCodeController.text,
          fullName: _fullNameController.text,
          phone: _phoneController.text,
        );
      } else {
        response = await _authRepository.signUpNewClient(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text,
          phone: _phoneController.text,
          establishmentIco: _icoController.text,
          establishmentName: _establishmentNameController.text,
          establishmentAddress: _establishmentAddressController.text,
          establishmentContactPhone: _establishmentPhoneController.text,
        );
      }

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
        'Не удалось зарегистрироваться. Проверьте введённые данные и '
        'подключение к интернету.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('ičo') || lower.contains('ico')) {
      return 'Заведение с таким IČO уже зарегистрировано в системе. '
          'Обратитесь к администратору сервисной компании.';
    }
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 20),
                    if (_isClient) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('У меня есть код приглашения'),
                        subtitle: Text(
                          _hasInviteCode
                              ? 'Код от сервисной компании привяжет вас к '
                                  'вашему заведению.'
                              : 'Без кода можно зарегистрироваться '
                                  'самостоятельно и завести своё заведение.',
                        ),
                        value: _hasInviteCode,
                        onChanged: (value) =>
                            setState(() => _hasInviteCode = value),
                      ),
                      const SizedBox(height: 8),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Для сотрудников регистрация только по коду '
                          'приглашения, выданному администратором '
                          'сервисной компании.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (_requiresInviteCode)
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
                      )
                    else ...[
                      Text(
                        'Ваше заведение',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _icoController,
                        keyboardType: TextInputType.number,
                        onChanged: _onIcoChanged,
                        decoration: InputDecoration(
                          labelText: 'IČO',
                          hintText: '8 цифр',
                          suffixIcon: _isLookingUpIco
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                          helperText: _icoLookupNote,
                        ),
                        validator: (value) => isValidCzechIco(value ?? '')
                            ? null
                            : 'Введите корректный IČO (8 цифр)',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _establishmentNameController,
                        decoration: const InputDecoration(
                          labelText: 'Название заведения',
                          hintText:
                              'Подставится из ARES или введите вручную',
                        ),
                        validator: (value) => (value == null ||
                                value.trim().isEmpty)
                            ? 'Введите название заведения'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _establishmentAddressController,
                        decoration:
                            const InputDecoration(labelText: 'Адрес'),
                        validator: (value) => (value == null ||
                                value.trim().isEmpty)
                            ? 'Введите адрес заведения'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _establishmentPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Контактный телефон заведения',
                        ),
                        validator: (value) => (value == null ||
                                value.trim().isEmpty)
                            ? 'Введите контактный телефон'
                            : null,
                      ),
                    ],
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
