import 'package:flutter/material.dart';

import '../../core/constants/equipment_status.dart';
import '../../models/equipment.dart';
import '../../models/establishment.dart';
import '../../services/equipment_repository.dart';
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
  final _repository = EquipmentRepository();
  late Future<List<Equipment>> _equipmentFuture;

  @override
  void initState() {
    super.initState();
    _equipmentFuture =
        _repository.fetchForEstablishment(widget.establishment.id);
  }

  Future<void> _refresh() async {
    final future = _repository.fetchForEstablishment(widget.establishment.id);
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

  @override
  Widget build(BuildContext context) {
    final establishment = widget.establishment;

    return Scaffold(
      appBar: AppBar(title: Text(establishment.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Добавить оборудование',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            Text('Оборудование', style: Theme.of(context).textTheme.titleSmall),
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
                    child: Text('Не удалось загрузить оборудование: ${snapshot.error}'),
                  );
                }

                final equipment = snapshot.data ?? const [];
                if (equipment.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Оборудование пока не добавлено'),
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
          child: const Icon(Icons.kitchen_outlined, color: Colors.white, size: 20),
        ),
        title: Text(equipment.type),
        subtitle: Text([
          if (equipment.model != null) equipment.model!,
          if (equipment.stickerCode != null) equipment.stickerCode!,
        ].join(' · ')),
        trailing: Chip(
          label: Text(
            equipment.status.label,
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
