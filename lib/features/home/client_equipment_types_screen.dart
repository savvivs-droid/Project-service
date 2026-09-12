import 'package:flutter/material.dart';

import '../../core/constants/equipment_icons.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/equipment_grid_tile.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/equipment.dart';
import '../../services/equipment_repository.dart';
import 'client_equipment_category_screen.dart';
import 'support_action_buttons.dart';

/// Виды оборудования внутри одной категории (например, в "Тепловое
/// оборудование" — конвектоматы, печи, плиты и т. д., см.
/// equipmentTypesForCategory). Промежуточный экран между сеткой
/// категорий на вкладке "Моё оборудование" и списком конкретных
/// единиц техники — категория "Другое" сюда не ведёт, у нее нет
/// фиксированных видов, там сразу список.
class ClientEquipmentTypesScreen extends StatefulWidget {
  const ClientEquipmentTypesScreen({
    super.key,
    required this.establishmentId,
    required this.clientId,
    required this.category,
  });

  final String establishmentId;
  final String clientId;
  final EquipmentCategory category;

  @override
  State<ClientEquipmentTypesScreen> createState() =>
      _ClientEquipmentTypesScreenState();
}

class _ClientEquipmentTypesScreenState
    extends State<ClientEquipmentTypesScreen> {
  final _repository = EquipmentRepository();
  late Future<List<Equipment>> _equipmentFuture;

  @override
  void initState() {
    super.initState();
    _equipmentFuture = _fetch();
  }

  Future<List<Equipment>> _fetch() {
    return _repository.fetchForEstablishment(widget.establishmentId);
  }

  Future<void> _refresh() async {
    final future = _fetch();
    setState(() => _equipmentFuture = future);
    await future;
  }

  void _openType(EquipmentTypeKey key) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientEquipmentCategoryScreen(
          establishmentId: widget.establishmentId,
          clientId: widget.clientId,
          typeKey: key,
          title: key.label(context),
          icon: key.icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final types = equipmentTypesForCategory(widget.category);

    return Scaffold(
      appBar: AppBar(
        title: AppBrandAppBarTitle(subtitle: widget.category.label(context)),
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
          int countFor(EquipmentTypeKey key) => equipment
              .where((item) => equipmentTypeKeyFromStorage(item.type) == key)
              .length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
              ),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final key = types[index];
                return EquipmentGridTile(
                  icon: key.icon,
                  photoAsset: key.photoAsset,
                  label: key.label(context),
                  count: countFor(key),
                  onTap: () => _openType(key),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
