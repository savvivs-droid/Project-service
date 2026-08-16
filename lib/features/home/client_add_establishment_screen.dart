import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/ico_validator.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/establishment.dart';
import '../../services/ares_service.dart';
import '../../services/establishment_repository.dart';

/// Клиент заводит себе ещё одно заведение (в дополнение к уже имеющимся) —
/// та же форма ИЧО+ARES-автоподстановка+адрес, что и при регистрации, плюс
/// контактный телефон (личный телефон клиента здесь не переиспользуешь —
/// его не вводят заново на этом экране). См. EstablishmentRepository и
/// add_client_establishment в supabase/schema.sql.
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

  final _icoController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSaving = false;

  Timer? _icoDebounce;
  bool _isLookingUpIco = false;
  String? _icoLookupNote;

  @override
  void dispose() {
    _icoDebounce?.cancel();
    _icoController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
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
        _nameController.text = company.name;
        if (company.address != null) {
          _addressController.text = company.address!;
        }
        _icoLookupNote = context.l10n.registerIcoFoundInAres;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final establishment = await _repository.addForCurrentClient(
        ico: _icoController.text,
        name: _nameController.text,
        address: _addressController.text,
        contactPhone: _phoneController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop<Establishment>(establishment);
    } catch (e) {
      if (!mounted) return;
      _showMessage(_translateError(e.toString()));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _translateError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('ičo') || lower.contains('ico')) {
      return context.l10n.registerIcoAlreadyRegistered;
    }
    return context.l10n.addEstablishmentGenericError;
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
                      controller: _nameController,
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
