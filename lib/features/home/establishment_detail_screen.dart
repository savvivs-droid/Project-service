import 'package:flutter/material.dart';

import '../../core/constants/equipment_icons.dart';
import '../../core/constants/equipment_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/equipment.dart';
import '../../models/establishment.dart';
import '../../services/equipment_repository.dart';
import '../../services/establishment_repository.dart';
import '../../services/photo_upload_service.dart';
import 'equipment_form_screen.dart';

class EstablishmentDetailScreen extends StatefulWidget {
  const EstablishmentDetailScreen({super.key, required this.establishment});

  final Establishment establishment;

  @override
  State<EstablishmentDetailScreen> createState() =>
      _EstablishmentDetailScreenState();
}

class _EstablishmentDetailScreenState
    extends State<EstablishmentDetailScreen> {
  final _equipmentRepository = EquipmentRepository();
  final _establishmentRepository = EstablishmentRepository();
  final _photoService = PhotoUploadService();

  late Future<List<Equipment>> _equipmentFuture;
  late String? _entrancePhotoUrl;
  bool _isSavingEntrancePhoto = false;

  @override
  void initState() {
    super.initState();
    _equipmentFuture =
        _equipmentRepository.fetchForEstablishment(widget.establishment.id);
    _entrancePhotoUrl = widget.establishment.entrancePhotoUrl;
  }

  Future<void> _refresh() async {
    final future =
        _equipmentRepository.fetchForEstablishment(widget.establishment.id);
    setState(() => _equipmentFuture = future);
    await future;
  }

  Future<void> _openForm({Equipment? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EquipmentFormScreen(
          establishmentId: widget.establishment.id,
          existing: existing,
        ),
      ),
    );
    if (saved == true) _refresh();
  }

  Future<void> _pickEntrancePhoto() async {
    final bytes = await pickImageBytes(context);
    if (bytes == null) return;

    setState(() => _isSavingEntrancePhoto = true);
    try {
      final url = await _photoService.upload(
        folder: '${widget.establishment.id}/entrance',
        bytes: bytes,
      );
      await _establishmentRepository.updateEntrancePhoto(
        id: widget.establishment.id,
        entrancePhotoUrl: url,
      );
      if (mounted) setState(() => _entrancePhotoUrl = url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.photoSaveError)),
      );
    } finally {
      if (mounted) setState(() => _isSavingEntrancePhoto = false);
    }
  }

  Future<void> _removeEntrancePhoto() async {
    setState(() => _isSavingEntrancePhoto = true);
    try {
      await _establishmentRepository.updateEntrancePhoto(
        id: widget.establishment.id,
        entrancePhotoUrl: null,
      );
      if (mounted) setState(() => _entrancePhotoUrl = null);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.photoDeleteError)),
      );
    } finally {
      if (mounted) setState(() => _isSavingEntrancePhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final establishment = widget.establishment;

    return Scaffold(
      appBar: AppBar(
        title: Text(establishment.name),
        actions: const [LanguageSwitcher()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: context.l10n.addEquipmentTooltip,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(context.l10n.entranceSectionTitle,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _EntrancePhoto(
              url: _entrancePhotoUrl,
              isSaving: _isSavingEntrancePhoto,
              onAddOrReplace: _pickEntrancePhoto,
              onRemove: _removeEntrancePhoto,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (establishment.address != null)
                      _InfoRow(icon: Icons.place_outlined, text: establishment.address!),
                    if (establishment.contactPhone != null)
                      _InfoRow(
                        icon: Icons.call_outlined,
                        text: establishment.contactPhone!,
                      ),
                    if (establishment.ico != null)
                      _InfoRow(icon: Icons.badge_outlined, text: 'IČO ${establishment.ico}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(context.l10n.equipmentLabel,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            FutureBuilder<List<Equipment>>(
              future: _equipmentFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      context.l10n.equipmentLoadError(snapshot.error.toString()),
                    ),
                  );
                }

                final equipment = snapshot.data ?? const [];
                if (equipment.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(context.l10n.noEquipmentYet),
                  );
                }

                return Column(
                  children: [
                    for (final item in equipment)
                      _EquipmentTile(
                        equipment: item,
                        onTap: () => _openForm(existing: item),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }
}

class _EntrancePhoto extends StatelessWidget {
  const _EntrancePhoto({
    required this.url,
    required this.isSaving,
    required this.onAddOrReplace,
    required this.onRemove,
  });

  final String? url;
  final bool isSaving;
  final VoidCallback onAddOrReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (url == null) {
      return InkWell(
        onTap: isSaving ? null : onAddOrReplace,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Center(
            child: isSaving
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.addEntrancePhotoLabel,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.network(
            url!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          if (isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _RoundIconButton(
                  icon: Icons.edit_outlined,
                  onTap: isSaving ? null : onAddOrReplace,
                ),
                const SizedBox(width: 8),
                _RoundIconButton(
                  icon: Icons.close,
                  onTap: isSaving ? null : onRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  const _EquipmentTile({required this.equipment, required this.onTap});

  final Equipment equipment;
  final VoidCallback onTap;

  Color _statusColor(BuildContext context) => switch (equipment.status) {
        EquipmentStatus.active => const Color(0xFF2F9E63),
        EquipmentStatus.inRepair => const Color(0xFF2F6FED),
        EquipmentStatus.decommissioned => const Color(0xFF6E7B93),
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _statusColor(context),
          child: Icon(
            equipmentTypeIcon(equipment.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(equipmentTypeLabel(context, equipment.type)),
        subtitle: Text([
          if (equipment.model != null) equipment.model!,
          if (equipment.stickerCode != null) equipment.stickerCode!,
        ].join(' · ')),
        trailing: Chip(
          label: Text(
            equipment.status.label(context),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: _statusColor(context),
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
