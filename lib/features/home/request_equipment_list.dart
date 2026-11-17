import 'package:flutter/material.dart';

import '../../core/constants/equipment_icons.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../models/request_list_item.dart';
import 'equipment_detail_screen.dart';

/// Блок "Оборудование" в карточке заявки: фото, название и вид каждой
/// единицы; тап — карточка оборудования (EquipmentDetailScreen).
class RequestEquipmentList extends StatelessWidget {
  const RequestEquipmentList({super.key, required this.refs});

  final List<EquipmentRef> refs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(context.l10n.equipmentLabel,
                  style: theme.textTheme.labelMedium),
            ),
            if (refs.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(context.l10n.notSpecified),
              ),
            for (final ref in refs) _EquipmentRow(ref: ref),
          ],
        ),
      ),
    );
  }
}

class _EquipmentRow extends StatelessWidget {
  const _EquipmentRow({required this.ref});

  final EquipmentRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = ref.details;
    final photoUrl = ref.photoUrl;
    final hasModel = ref.model?.isNotEmpty == true;
    final subtitle = [
      if (hasModel) equipmentTypeLabel(context, ref.type),
      if (ref.stickerCode?.isNotEmpty == true) ref.stickerCode!,
    ].join(' · ');

    return ListTile(
      onTap: details == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EquipmentDetailScreen(equipment: details),
                ),
              ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: photoUrl == null
              ? ColoredBox(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  child: Icon(equipmentTypeIcon(ref.type),
                      color: theme.colorScheme.primary),
                )
              : Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    equipmentTypeIcon(ref.type),
                    color: theme.colorScheme.primary,
                  ),
                ),
        ),
      ),
      title: Text(ref.name(context)),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: details == null ? null : const Icon(Icons.chevron_right),
    );
  }
}
