import 'package:flutter/widgets.dart';

import '../l10n/l10n_extension.dart';

/// Статус оборудования.
///
/// Значения совпадают со значениями enum equipment_status в базе данных.
enum EquipmentStatus { active, inRepair, decommissioned }

extension EquipmentStatusX on EquipmentStatus {
  String get value => switch (this) {
        EquipmentStatus.active => 'active',
        EquipmentStatus.inRepair => 'in_repair',
        EquipmentStatus.decommissioned => 'decommissioned',
      };

  String label(BuildContext context) => switch (this) {
        EquipmentStatus.active => context.l10n.statusEquipmentActive,
        EquipmentStatus.inRepair => context.l10n.statusEquipmentInRepair,
        EquipmentStatus.decommissioned =>
          context.l10n.statusEquipmentDecommissioned,
      };

  static EquipmentStatus fromValue(String value) {
    return EquipmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EquipmentStatus.active,
    );
  }
}
