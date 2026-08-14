import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/constants/equipment_icons.dart';
import '../../core/constants/equipment_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../models/equipment.dart';
import '../../services/photo_upload_service.dart';
import '../../services/equipment_repository.dart';

const _otherTypeSentinel = '__other__';

/// Фото в форме — либо уже загруженное (есть [url]), либо только что
/// выбранное на устройстве и ещё не загруженное в Storage (есть [bytes]).
class _PhotoItem {
  final String? url;
  final Uint8List? bytes;

  const _PhotoItem.existing(String this.url) : bytes = null;
  const _PhotoItem.picked(Uint8List this.bytes) : url = null;
}

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
  final _photoService = PhotoUploadService();

  late final TextEditingController _customTypeController;
  late final TextEditingController _modelController;

  String? _selectedType;
  bool _showTypeError = false;
  late EquipmentStatus _status;
  DateTime? _installedAt;
  bool _isSaving = false;

  _PhotoItem? _stickerPhoto;
  final List<_PhotoItem> _photos = [];

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
    _status = existing?.status ?? EquipmentStatus.active;
    _installedAt = existing?.installedAt;

    final existingStickerUrl = existing?.stickerPhotoUrl;
    if (existingStickerUrl != null) {
      _stickerPhoto = _PhotoItem.existing(existingStickerUrl);
    }
    for (final url in existing?.photos ?? const <String>[]) {
      _photos.add(_PhotoItem.existing(url));
    }
  }

  @override
  void dispose() {
    _customTypeController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _selectType(String value) {
    setState(() {
      _selectedType = value;
      _showTypeError = false;
    });
  }

  Future<void> _pickStickerPhoto() async {
    final bytes = await pickImageBytes(context);
    if (bytes != null) setState(() => _stickerPhoto = _PhotoItem.picked(bytes));
  }

  Future<void> _addPhoto() async {
    final bytes = await pickImageBytes(context);
    if (bytes != null) setState(() => _photos.add(_PhotoItem.picked(bytes)));
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

  Future<String> _resolveUrl(_PhotoItem item) async {
    if (item.url != null) return item.url!;
    return _photoService.upload(
      folder: '${widget.establishmentId}/equipment',
      bytes: item.bytes!,
    );
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

      final stickerPhotoUrl =
          _stickerPhoto == null ? null : await _resolveUrl(_stickerPhoto!);
      final photoUrls = [for (final photo in _photos) await _resolveUrl(photo)];

      if (_isEditing) {
        await _repository.update(
          id: widget.existing!.id,
          type: type,
          status: _status,
          model: model.isEmpty ? null : model,
          stickerPhotoUrl: stickerPhotoUrl,
          photos: photoUrls,
          installedAt: _installedAt,
        );
      } else {
        await _repository.create(
          establishmentId: widget.establishmentId,
          type: type,
          status: _status,
          model: model.isEmpty ? null : model,
          stickerPhotoUrl: stickerPhotoUrl,
          photos: photoUrls,
          installedAt: _installedAt,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.equipmentSaveError)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? context.l10n.equipmentFormEditTitle
            : context.l10n.equipmentFormNewTitle),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isSaving,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(context.l10n.equipmentTypeSectionTitle,
                    style: Theme.of(context).textTheme.titleSmall),
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
                      label: context.l10n.equipmentTypeOther,
                      selected: _selectedType == _otherTypeSentinel,
                      onTap: () => _selectType(_otherTypeSentinel),
                    ),
                  ],
                ),
                if (_showTypeError) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.equipmentTypeRequired,
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
                    decoration: InputDecoration(
                      labelText: context.l10n.equipmentTypeCustomLabel,
                    ),
                    validator: (value) {
                      if (_selectedType != _otherTypeSentinel) return null;
                      return (value == null || value.trim().isEmpty)
                          ? context.l10n.equipmentTypeCustomRequired
                          : null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(labelText: context.l10n.modelLabel),
                ),
                const SizedBox(height: 20),
                Text(context.l10n.stickerPhotoSectionTitle,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  context.l10n.stickerPhotoHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _PhotoThumb(
                  item: _stickerPhoto,
                  onAdd: _pickStickerPhoto,
                  onRemove: () => setState(() => _stickerPhoto = null),
                ),
                const SizedBox(height: 20),
                Text(context.l10n.equipmentPhotosSectionTitle,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < _photos.length; i++)
                      _PhotoThumb(
                        item: _photos[i],
                        onRemove: () => setState(() => _photos.removeAt(i)),
                      ),
                    _PhotoThumb(item: null, onAdd: _addPhoto),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<EquipmentStatus>(
                  initialValue: _status,
                  decoration:
                      InputDecoration(labelText: context.l10n.statusDropdownLabel),
                  items: [
                    for (final status in EquipmentStatus.values)
                      DropdownMenuItem(
                          value: status, child: Text(status.label(context))),
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
                        ? context.l10n.installedAtNotSet
                        : context.l10n.installedAtSet(_formatDate(_installedAt!)),
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
                      : Text(context.l10n.saveButton),
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

/// Миниатюра фото с кнопкой удаления, либо (если [item] равен null)
/// плитка "добавить фото".
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.item, this.onAdd, this.onRemove});

  final _PhotoItem? item;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (item == null) {
      return InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Icon(Icons.add_a_photo_outlined, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    final image = item!.bytes != null
        ? Image.memory(item!.bytes!, width: 84, height: 84, fit: BoxFit.cover)
        : Image.network(item!.url!, width: 84, height: 84, fit: BoxFit.cover);

    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
