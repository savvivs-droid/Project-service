import 'package:flutter/material.dart';

import '../../core/constants/equipment_status.dart';
import '../../models/equipment.dart';
import '../../services/equipment_repository.dart';

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

  late final TextEditingController _typeController;
  late final TextEditingController _modelController;
  late final TextEditingController _stickerCodeController;

  late EquipmentStatus _status;
  DateTime? _installedAt;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _typeController = TextEditingController(text: existing?.type ?? '');
    _modelController = TextEditingController(text: existing?.model ?? '');
    _stickerCodeController =
        TextEditingController(text: existing?.stickerCode ?? '');
    _status = existing?.status ?? EquipmentStatus.active;
    _installedAt = existing?.installedAt;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _modelController.dispose();
    _stickerCodeController.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final type = _typeController.text.trim();
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
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Тип оборудования',
                    hintText: 'Например, Пароконвектомат',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Введите тип оборудования'
                      : null,
                ),
                const SizedBox(height: 16),
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

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
