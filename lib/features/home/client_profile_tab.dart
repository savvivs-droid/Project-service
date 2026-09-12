import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/text_formatters.dart';
import '../../models/profile.dart';
import '../../services/auth_repository.dart';
import '../../services/profile_repository.dart';

/// Вкладка профиля клиента — редактирование имени/телефона, смена email
/// и пароля. Роль и заведение здесь не меняются: это защищено RLS
/// (см. trg_protect_profile_privileges в supabase/schema.sql).
class ClientProfileTab extends StatefulWidget {
  const ClientProfileTab({super.key, required this.profile});

  final Profile profile;

  @override
  State<ClientProfileTab> createState() => _ClientProfileTabState();
}

class _ClientProfileTabState extends State<ClientProfileTab> {
  final _profileFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _profileRepository = ProfileRepository();
  final _authRepository = AuthRepository();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _newPasswordController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingEmail = false;
  bool _isSavingPassword = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.profile.fullName ?? '');
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _emailController =
        TextEditingController(text: _authRepository.currentUser?.email ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);
    try {
      await _profileRepository.updateProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) _showMessage(context.l10n.profileSaved);
    } catch (_) {
      if (mounted) _showMessage(context.l10n.profileSaveError);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _saveEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isSavingEmail = true);
    try {
      await _authRepository.updateEmail(_emailController.text.trim());
      if (mounted) _showMessage(context.l10n.emailChangeRequested);
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) _showMessage(context.l10n.emailChangeError);
    } finally {
      if (mounted) setState(() => _isSavingEmail = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isSavingPassword = true);
    try {
      await _authRepository.updatePassword(_newPasswordController.text);
      _newPasswordController.clear();
      if (mounted) _showMessage(context.l10n.passwordChanged);
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) _showMessage(context.l10n.passwordChangeError);
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteAccountDialogTitle),
        content: Text(context.l10n.deleteAccountDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.deleteAccountDialogCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.deleteAccountDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeletingAccount = true);
    try {
      await _authRepository.deleteOwnAccount();
      // AuthRepository.deleteOwnAccount уже завершает сессию сам —
      // AuthGate заметит это и покажет экран входа, дополнительная
      // навигация отсюда не нужна.
    } catch (_) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        _showMessage(context.l10n.deleteAccountError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.l10n.profilePersonalDataTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                inputFormatters: const [CapitalizeFirstLetterFormatter()],
                decoration:
                    InputDecoration(labelText: context.l10n.registerFullNameLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? context.l10n.registerFullNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration:
                    InputDecoration(labelText: context.l10n.registerPhoneLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? context.l10n.registerPhoneRequired
                    : null,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _isSavingProfile ? null : _saveProfile,
                  child: _isSavingProfile
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.saveButton),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 12),
        Text(context.l10n.profileEmailSectionTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(context.l10n.profileEmailHint,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Form(
          key: _emailFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    InputDecoration(labelText: context.l10n.loginEmailLabel),
                validator: (value) => (value == null || !value.contains('@'))
                    ? context.l10n.loginEmailInvalid
                    : null,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: _isSavingEmail ? null : _saveEmail,
                  child: _isSavingEmail
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.profileChangeEmailButton),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 12),
        Text(context.l10n.profilePasswordSectionTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: context.l10n.profileNewPasswordLabel),
                validator: (value) => (value == null || value.length < 6)
                    ? context.l10n.loginPasswordTooShort
                    : null,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: _isSavingPassword ? null : _savePassword,
                  child: _isSavingPassword
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.profileChangePasswordButton),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 12),
        Text(context.l10n.deleteAccountSectionTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(context.l10n.deleteAccountHint,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: _isDeletingAccount ? null : _deleteAccount,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            child: _isDeletingAccount
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.deleteAccountButton),
          ),
        ),
      ],
    );
  }
}
