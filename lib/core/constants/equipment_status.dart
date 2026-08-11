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

  String get label => switch (this) {
        EquipmentStatus.active => 'Работает',
        EquipmentStatus.inRepair => 'В ремонте',
        EquipmentStatus.decommissioned => 'Списано',
      };

  static EquipmentStatus fromValue(String value) {
    return EquipmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EquipmentStatus.active,
    );
  }
}
