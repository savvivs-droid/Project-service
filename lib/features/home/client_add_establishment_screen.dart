import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/text_formatters.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/establishment.dart';
import '../../services/establishment_repository.dart';

/// Клиент заводит себе ещё одно заведение (в дополнение к уже имеющимся) —
/// название, адрес и контактный телефон (личный телефон клиента здесь не
/// переиспользуешь — его не вводят заново на этом экране). Без IČO —
/// в отличие от регистрации, здесь это поле только создавало путаницу
/// (ошибка при совпадении с уже существующим заведением), а пользы от
/// автоподстановки ARES для второго и последующих заведений немного.
/// См. EstablishmentRepository и add_client_establishment в
/// supabase/schema.sql.
class ClientAddEstablishmentScreen extends StatefulWidget {
  const ClientAddEstablishmentScreen({super.key});

  @override
  State<ClientAddEstablishmentScreen> createState() =>
      _ClientAddEstablishmentScreenState();
}

class _ClientAddEstablishmentScreenState
    extends State<ClientAddEstablishmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = EstablishmentRepository();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final establishment = await _repository.addForCurrentClient(
        name: _nameController.text,
        address: _addressController.text,
        contactPhone: _phoneController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop<Establishment>(establishment);
    } catch (e) {
      if (!mounted) return;
      _showMessage(context.l10n.addEstablishmentGenericError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        title: AppBrandAppBarTitle(subtitle: context.l10n.addEstablishmentTitle),
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
                    TextFormField(
                      controller: _nameController,
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
                      controller: _addressController,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: const [CapitalizeFirstLetterFormatter()],
                      decoration: InputDecoration(
                          labelText: context.l10n.registerAddressLabel),
                      validator: (value) => (value == null ||
                              value.trim().isEmpty)
                          ? context.l10n.registerAddressRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: context.l10n.addEstablishmentPhoneLabel,
                      ),
                      validator: (value) => (value == null ||
                              value.trim().isEmpty)
                          ? context.l10n.addEstablishmentPhoneRequired
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.addEstablishmentSubmitButton),
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
