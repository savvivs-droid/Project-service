import 'package:flutter/material.dart';

import '../../core/constants/equipment_icons.dart';
import '../../core/constants/equipment_status.dart';
import '../../models/equipment.dart';
import '../../services/equipment_repository.dart';

const _otherTypeSentinel = '__other__';

/// Форма добавления или редактирования оборудования. Если [existing]
/// передан — форма работает на редактирование, иначе создаёт новую запись.
class EquipmentFormScreen extends StatefulWidget {
  const EquipmentFormScreen({
    super.key,
    required this.establishmentId,
    this.existing,
  });

  final String establishmentId;
  final Equipment? existing;

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = EquipmentRepository();

  late final TextEditingController _customTypeController;
  late final TextEditingController _modelController;
  late final TextEditingController _stickerCodeController;

  String? _selectedType;
  bool _showTypeError = false;
  late EquipmentStatus _status;
  DateTime? _installedAt;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    final existingType = existing?.type;
    if (existingType == null) {
      _selectedType = null;
    } else if (equipmentTypeOptions.any((option) => option.label == existingType)) {
      _selectedType = existingType;
    } else {
      _selectedType = _otherTypeSentinel;
    }

    _customTypeController = TextEditingController(
      text: _selectedType == _otherTypeSentinel ? existingType : '',
    );
    _modelController = TextEditingController(text: existing?.model ?? '');
    _stickerCodeController =
        TextEditingController(text: existing?.stickerCode ?? '');
    _status = existing?.status ?? EquipmentStatus.active;
    _installedAt = existing?.installedAt;
  }

  @override
  void dispose() {
    _customTypeController.dispose();
    _modelController.dispose();
    _stickerCodeController.dispose();
    super.dispose();
  }

  void _selectType(String value) {
    setState(() {
      _selectedType = value;
      _showTypeError = false;
    });
  }

  Future<void> _pickInstalledAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _installedAt ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (picked != null) setState(() => _installedAt = picked);
  }

  Future<void> _submit() async {
    if (_selectedType == null) {
      setState(() => _showTypeError = true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final type = _selectedType == _otherTypeSentinel
        ? _customTypeController.text.trim()
        : _selectedType!;

    setState(() => _isSaving = true);
    try {
      final model = _modelController.text.trim();
      final stickerCode = _stickerCodeController.text.trim();

      if (_isEditing) {
        await _repository.update(
          id: widget.existing!.id,
          type: type,
          status: _status,
          model: model.isEmpty ? null : model,
          stickerCode: stickerCode.isEmpty ? null : stickerCode,
          installedAt: _installedAt,
        );
      } else {
        await _repository.create(
          establishmentId: widget.establishmentId,
          type: type,
          status: _status,
          model: model.isEmpty ? null : model,
          stickerCode: stickerCode.isEmpty ? null : stickerCode,
          installedAt: _installedAt,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().toLowerCase().contains('sticker_code')
          ? 'Такой код стикера уже используется другим оборудованием.'
          : 'Не удалось сохранить оборудование.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Изменить оборудование' : 'Новое оборудование'),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isSaving,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Тип оборудования', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final option in equipmentTypeOptions)
                      _TypeOptionTile(
                        icon: option.icon,
                        label: option.label,
                        selected: _selectedType == option.label,
                        onTap: () => _selectType(option.label),
                      ),
                    _TypeOptionTile(
                      icon: Icons.more_horiz,
                      label: 'Другое',
                      selected: _selectedType == _otherTypeSentinel,
                      onTap: () => _selectType(_otherTypeSentinel),
                    ),
                  ],
                ),
                if (_showTypeError) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Выберите тип оборудования',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (_selectedType == _otherTypeSentinel) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Укажите тип оборудования',
                    ),
                    validator: (value) {
                      if (_selectedType != _otherTypeSentinel) return null;
                      return (value == null || value.trim().isEmpty)
                          ? 'Введите тип оборудования'
                          : null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: 'Модель'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stickerCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Код стикера',
                    hintText: 'Например, EQ-0231',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EquipmentStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Статус'),
                  items: [
                    for (final status in EquipmentStatus.values)
                      DropdownMenuItem(value: status, child: Text(status.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickInstalledAt,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _installedAt == null
                        ? 'Дата установки не указана'
                        : 'Установлено: ${_formatDate(_installedAt!)}',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            ),
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
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
            Icon(
              icon,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? colorScheme.primary : null,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
