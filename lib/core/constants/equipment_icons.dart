import 'package:flutter/material.dart';

/// Один пункт визуального выбора типа оборудования на форме добавления.
class EquipmentTypeOption {
  final String label;
  final IconData icon;

  const EquipmentTypeOption({required this.label, required this.icon});
}

/// Самые частые типы оборудования гастрокухни — показываются иконками
/// с подписью на форме добавления. Список не исчерпывающий: для всего
/// остального на форме есть пункт "Другое" со свободным текстом (тип
/// в базе — обычный text, не enum, поэтому список ничего не ограничивает).
const List<EquipmentTypeOption> equipmentTypeOptions = [
  EquipmentTypeOption(label: 'Холодильник', icon: Icons.ac_unit_outlined),
  EquipmentTypeOption(label: 'Морозильная камера', icon: Icons.severe_cold_outlined),
  EquipmentTypeOption(label: 'Пароконвектомат', icon: Icons.microwave_outlined),
  EquipmentTypeOption(label: 'Плита', icon: Icons.local_fire_department_outlined),
  EquipmentTypeOption(
    label: 'Посудомоечная машина',
    icon: Icons.local_laundry_service_outlined,
  ),
  EquipmentTypeOption(label: 'Гриль', icon: Icons.outdoor_grill_outlined),
  EquipmentTypeOption(label: 'Кофемашина', icon: Icons.coffee_maker_outlined),
  EquipmentTypeOption(label: 'Миксер/блендер', icon: Icons.blender_outlined),
  EquipmentTypeOption(label: 'Разделочный стол', icon: Icons.countertops_outlined),
];

/// Подбирает иконку по названию типа оборудования (свободный текст) —
/// используется в списке оборудования, где тип уже задан. Ищет по
/// ключевым словам, покрывает варианты из [equipmentTypeOptions] и
/// немного шире. Для нераспознанного типа — нейтральная иконка.
IconData iconForEquipmentType(String type) {
  final normalized = type.toLowerCase();
  bool has(String keyword) => normalized.contains(keyword);

  if (has('посудомо')) return Icons.local_laundry_service_outlined;
  if (has('морозил')) return Icons.severe_cold_outlined;
  if (has('холодильн') || has('камера')) return Icons.ac_unit_outlined;
  if (has('пароконвектомат') || has('конвектомат') || has('духов') || has('печь')) {
    return Icons.microwave_outlined;
  }
  if (has('плита') || has('варочн')) return Icons.local_fire_department_outlined;
  if (has('гриль')) return Icons.outdoor_grill_outlined;
  if (has('кофе')) return Icons.coffee_maker_outlined;
  if (has('миксер') || has('блендер')) return Icons.blender_outlined;
  if (has('стол') || has('поверхност')) return Icons.countertops_outlined;

  return Icons.kitchen_outlined;
}
