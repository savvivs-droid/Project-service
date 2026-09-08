import 'package:flutter/material.dart';

import '../../core/constants/equipment_icons.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/text_formatters.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/equipment.dart';
import '../../services/equipment_repository.dart';
import '../../services/service_request_repository.dart';

/// Форма создания заявки на ремонт клиентом: вид техники → конкретный
/// прибор → краткое описание проблемы. Список оборудования на выбор —
/// только то, что реально числится за выбранным заведением клиента
/// (добавляет и редактирует оборудование только администратор, см.
/// EstablishmentDetailScreen).
class ClientCreateRequestScreen extends StatefulWidget {
  const ClientCreateRequestScreen({
    super.key,
    required this.establishmentId,
    required this.clientId,
  });

  final String establishmentId;
  final String clientId;

  @override
  State<ClientCreateRequestScreen> createState() =>
      _ClientCreateRequestScreenState();
}

class _ClientCreateRequestScreenState
    extends State<ClientCreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentRepository = EquipmentRepository();
  final _requestRepository = ServiceRequestRepository();
  final _descriptionController = TextEditingController();

  late Future<List<Equipment>> _equipmentFuture;
  EquipmentTypeKey? _selectedType;
  bool _otherTypeSelected = false;
  Equipment? _selectedEquipment;
  bool _showEquipmentError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _equipmentFuture =
        _equipmentRepository.fetchForEstablishment(widget.establishmentId);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectType(EquipmentTypeKey? key, bool other) {
    setState(() {
      _selectedType = key;
      _otherTypeSelected = other;
      _selectedEquipment = null;
    });
  }

  void _selectEquipment(Equipment equipment) {
    setState(() {
      _selectedEquipment = equipment;
      _showEquipmentError = false;
    });
  }

  Future<void> _submit() async {
    if (_selectedEquipment == null) {
      setState(() => _showEquipmentError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _requestRepository.create(
        establishmentId: widget.establishmentId,
        clientId: widget.clientId,
        description: _descriptionController.text.trim(),
        equipmentIds: [_selectedEquipment!.id],
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.createRequestError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBrandAppBarTitle(subtitle: context.l10n.createRequestTitle),
        actions: const [LanguageSwitcher()],
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isSaving,
          child: FutureBuilder<List<Equipment>>(
            future: _equipmentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.equipmentLoadError(snapshot.error.toString()),
                    ),
                  ),
                );
              }

              final equipment = snapshot.data ?? const [];
              if (equipment.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(context.l10n.noEquipmentYet),
                  ),
                );
              }

              // Только те типы, по которым у заведения реально есть
              // оборудование — выбирать нечего, если по типу пусто.
              final types = <EquipmentTypeKey?>[];
              for (final item in equipment) {
                final key = equipmentTypeKeyFromStorage(item.type);
                if (!types.contains(key)) types.add(key);
              }
              types.sort((a, b) {
                if (a == null) return 1;
                if (b == null) return -1;
                return a.index.compareTo(b.index);
              });

              final matchingEquipment = _selectedType == null &&
                      !_otherTypeSelected
                  ? const <Equipment>[]
                  : equipment
                      .where((item) =>
                          equipmentTypeKeyFromStorage(item.type) ==
                          (_otherTypeSelected ? null : _selectedType))
                      .toList();

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(context.l10n.createRequestTypeSectionTitle,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final key in types)
                          _TypeOptionTile(
                            icon: key?.icon ?? Icons.more_horiz,
                            photoAsset: key?.photoAsset ??
                                EquipmentCategory.other.photoAsset,
                            label: key?.label(context) ??
                                context.l10n.equipmentTypeOther,
                            selected: key == null
                                ? _otherTypeSelected
                                : _selectedType == key,
                            onTap: () => _selectType(key, key == null),
                          ),
                      ],
                    ),
                    if (matchingEquipment.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(context.l10n.createRequestEquipmentSectionTitle,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 12),
                      for (final item in matchingEquipment)
                        _EquipmentOptionTile(
                          equipment: item,
                          selected: _selectedEquipment?.id == item.id,
                          onTap: () => _selectEquipment(item),
                        ),
                    ],
                    if (_showEquipmentError) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.createRequestEquipmentRequired,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_selectedEquipment != null) ...[
                      const SizedBox(height: 20),
                      Text(context.l10n.createRequestDescriptionSectionTitle,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: const [CapitalizeFirstLetterFormatter()],
                        decoration: InputDecoration(
                          hintText: context.l10n.createRequestDescriptionHint,
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? context.l10n.createRequestDescriptionRequired
                                : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.createRequestSubmitButton),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TypeOptionTile extends StatelessWidget {
  const _TypeOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.photoAsset,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Настоящее фото прибора — то же, что на плитках категорий/видов
  /// на вкладке "Моё оборудование" (см. EquipmentGridTile). Если не
  /// задано, показывается иконка на цветной подложке-градиенте.
  final String? photoAsset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? colorScheme.primary.withValues(alpha: 0.08) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: photoAsset != null
                    ? Image.asset(photoAsset!, fit: BoxFit.cover)
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.14),
                              colorScheme.secondary.withValues(alpha: 0.16),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: 28,
                            color: selected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            // Фиксированная высота под подпись (до двух строк) — иначе
            // у плиток с короткой ("Плита") и длинной ("Холодильник",
            // "Посудомоечная машина") подписью получаются рамки разной
            // высоты, как в _CategoryTile на экране оборудования.
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected ? colorScheme.primary : null,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentOptionTile extends StatelessWidget {
  const _EquipmentOptionTile({
    required this.equipment,
    required this.selected,
    required this.onTap,
  });

  final Equipment equipment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: equipment.photos.isEmpty
            ? CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  equipmentTypeIcon(equipment.type),
                  color: colorScheme.primary,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  equipment.photos.first,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
        title: Text(
          equipment.model?.isNotEmpty == true
              ? equipment.model!
              : equipmentTypeLabel(context, equipment.type),
        ),
        subtitle: equipment.stickerCode == null
            ? null
            : Text(equipment.stickerCode!),
        trailing: selected
            ? Icon(Icons.check_circle, color: colorScheme.primary)
            : const Icon(Icons.radio_button_unchecked),
      ),
    );
  }
}
