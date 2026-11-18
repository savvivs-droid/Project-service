import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/ico_validator.dart';
import '../../core/utils/text_formatters.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/language_switcher.dart';
import '../../services/ares_service.dart';
import '../../services/auth_repository.dart';
import 'privacy_policy_screen.dart';

class _CountryDialCode {
  const _CountryDialCode(this.flag, this.dialCode);

  final String flag;
  final String dialCode;
}

// Чехия по умолчанию — сервис работает с чешскими заведениями (регистрация
// требует чешский IČO), остальные коды — для клиентов и персонала из
// соседних и целевых по локализации приложения стран.
const _dialCodes = [
  _CountryDialCode('🇨🇿', '+420'),
  _CountryDialCode('🇸🇰', '+421'),
  _CountryDialCode('🇩🇪', '+49'),
  _CountryDialCode('🇷🇺', '+7'),
  _CountryDialCode('🇺🇦', '+380'),
  _CountryDialCode('🇻🇳', '+84'),
];

/// Регистрация клиента. Это единственный способ создать аккаунт через
/// приложение — клиент сразу заводит своё заведение. Администраторов
/// заводят вручную сотрудники сервисной компании (см. supabase/schema.sql).
///
/// Контактный телефон вводится один раз (личный телефон клиента) и
/// используется и как телефон профиля, и как контактный телефон
/// заведения — отдельного поля для второго раньше не было смысла
/// заполнять дважды одним и тем же номером.
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
  final _icoController = TextEditingController();
  final _establishmentNameController = TextEditingController();
  final _establishmentAddressController = TextEditingController();

  _CountryDialCode _dialCode = _dialCodes.first;

  bool _isLoading = false;
  bool _agreedToPrivacyPolicy = false;

  Timer? _icoDebounce;
  bool _isLookingUpIco = false;
  String? _icoLookupNote;

  @override
  void dispose() {
    _icoDebounce?.cancel();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _icoController.dispose();
    _establishmentNameController.dispose();
    _establishmentAddressController.dispose();
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
        _icoLookupNote = context.l10n.registerIcoNotFoundInAres;
      } else {
        _establishmentNameController.text = company.name;
        if (company.address != null) {
          _establishmentAddressController.text = company.address!;
        }
        _icoLookupNote = context.l10n.registerIcoFoundInAres;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToPrivacyPolicy) {
      _showMessage(context.l10n.registerPrivacyConsentRequired);
      return;
    }

    final phone = '${_dialCode.dialCode} ${_phoneController.text.trim()}';

    setState(() => _isLoading = true);
    try {
      final AuthResponse response = await _authRepository.signUpNewClient(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text,
        phone: phone,
        establishmentIco: _icoController.text,
        establishmentName: _establishmentNameController.text,
        establishmentAddress: _establishmentAddressController.text,
        establishmentContactPhone: phone,
      );

      if (!mounted) return;

      if (response.session == null) {
        _showMessage(context.l10n.registerEmailConfirmationNeeded);
      }
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      _showMessage(_translateError(e.message));
    } catch (_) {
      _showMessage(context.l10n.registerGenericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('ičo') || lower.contains('ico')) {
      return context.l10n.registerIcoAlreadyRegistered;
    }
    if (lower.contains('already registered') ||
        lower.contains('already exists')) {
      return context.l10n.registerEmailAlreadyRegistered;
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
      appBar: AppBar(
        title: AppBrandAppBarTitle(subtitle: context.l10n.registerTitle),
        actions: const [LanguageSwitcher()],
      ),
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
                      context.l10n.registerEstablishmentSectionTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: const [CapitalizeFirstLetterFormatter()],
                      decoration: InputDecoration(
                          labelText: context.l10n.registerFullNameLabel),
                      validator: (value) => (value == null ||
                              value.trim().isEmpty)
                          ? context.l10n.registerFullNameRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: DropdownButtonFormField<_CountryDialCode>(
                            initialValue: _dialCode,
                            decoration: const InputDecoration(),
                            items: [
                              for (final code in _dialCodes)
                                DropdownMenuItem(
                                  value: code,
                                  child: Text('${code.flag} ${code.dialCode}'),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _dialCode = value!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                                labelText: context.l10n.registerPhoneLabel),
                            validator: (value) => (value == null ||
                                    value.trim().isEmpty)
                                ? context.l10n.registerPhoneRequired
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          InputDecoration(labelText: context.l10n.loginEmailLabel),
                      validator: (value) =>
                          (value == null || !value.contains('@'))
                              ? context.l10n.loginEmailInvalid
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: context.l10n.loginPasswordLabel),
                      validator: (value) =>
                          (value == null || value.length < 6)
                              ? context.l10n.loginPasswordTooShort
                              : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.registerYourEstablishmentTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _icoController,
                      keyboardType: TextInputType.number,
                      onChanged: _onIcoChanged,
                      decoration: InputDecoration(
                        labelText: context.l10n.registerIcoLabel,
                        hintText: context.l10n.registerIcoHint,
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
                          : context.l10n.registerIcoInvalid,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _establishmentNameController,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: const [CapitalizeFirstLetterFormatter()],
                      decoration: InputDecoration(
                        labelText: context.l10n.registerEstablishmentNameLabel,
                        hintText: context.l10n.registerEstablishmentNameHint,
                      ),
                      validator: (value) => (value == null ||
                              value.trim().isEmpty)
                          ? context.l10n.registerEstablishmentNameRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _establishmentAddressController,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: const [CapitalizeFirstLetterFormatter()],
                      decoration: InputDecoration(
                          labelText: context.l10n.registerAddressLabel),
                      validator: (value) => (value == null ||
                              value.trim().isEmpty)
                          ? context.l10n.registerAddressRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _agreedToPrivacyPolicy,
                      onChanged: (value) =>
                          setState(() => _agreedToPrivacyPolicy = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(context.l10n.registerPrivacyConsentPrefix),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyScreen(),
                              ),
                            ),
                            child: Text(
                              context.l10n.registerPrivacyConsentLinkText,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.registerSubmitButton),
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
