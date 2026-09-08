import 'package:flutter/material.dart';

import '../../core/constants/equipment_icons.dart';
import '../../core/constants/equipment_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/fullscreen_photo_viewer.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/equipment.dart';
import '../../services/equipment_repository.dart';
import 'support_action_buttons.dart';

/// Оборудование одной категории (например, все холодильники заведения).
/// Только чтение — добавляет и меняет оборудование только администратор,
/// см. EstablishmentDetailScreen.
class ClientEquipmentCategoryScreen extends StatefulWidget {
  const ClientEquipmentCategoryScreen({
    super.key,
    required this.establishmentId,
    required this.clientId,
    required this.typeKey,
    required this.title,
    required this.icon,
  });

  final String establishmentId;
  final String clientId;

  /// null — категория "Другое": оборудование со свободным типом, не
  /// попавшим ни в один из известных ключей.
  final EquipmentTypeKey? typeKey;

  final String title;
  final IconData icon;

  @override
  State<ClientEquipmentCategoryScreen> createState() =>
      _ClientEquipmentCategoryScreenState();
}

class _ClientEquipmentCategoryScreenState
    extends State<ClientEquipmentCategoryScreen> {
  final _repository = EquipmentRepository();
  late Future<List<Equipment>> _equipmentFuture;

  @override
  void initState() {
    super.initState();
    _equipmentFuture = _fetch();
  }

  Future<List<Equipment>> _fetch() async {
    final all = await _repository.fetchForEstablishment(widget.establishmentId);
    return all
        .where((item) => equipmentTypeKeyFromStorage(item.type) == widget.typeKey)
        .toList();
  }

  Future<void> _refresh() async {
    final future = _fetch();
    setState(() => _equipmentFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBrandAppBarTitle(subtitle: widget.title),
        actions: const [LanguageSwitcher()],
      ),
      floatingActionButton: SupportActionButtons(
        establishmentId: widget.establishmentId,
        clientId: widget.clientId,
      ),
      body: FutureBuilder<List<Equipment>>(
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
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(context.l10n.noEquipmentYet)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: equipment.length,
              itemBuilder: (context, index) =>
                  _EquipmentCard(equipment: equipment[index]),
            ),
          );
        },
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.equipment});

  final Equipment equipment;

  Color _statusColor(BuildContext context) => switch (equipment.status) {
        EquipmentStatus.active => const Color(0xFF2F9E63),
        EquipmentStatus.inRepair => const Color(0xFF2F6FED),
        EquipmentStatus.decommissioned => const Color(0xFF6E7B93),
      };

  @override
  Widget build(BuildContext context) {
    final photoUrl = equipment.photos.isEmpty ? null : equipment.photos.first;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: photoUrl == null
            ? CircleAvatar(
                backgroundColor: _statusColor(context),
                child: Icon(
                  equipmentTypeIcon(equipment.type),
                  color: Colors.white,
                  size: 20,
                ),
              )
            : GestureDetector(
                onTap: () => openFullscreenPhoto(context, photoUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    photoUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
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
