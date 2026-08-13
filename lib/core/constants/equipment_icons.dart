import 'package:flutter/material.dart';

/// Подбирает иконку по названию типа оборудования (это свободный текст,
/// который вводит администратор, — не enum). Ищет по ключевым словам,
/// покрывает самое частое оборудование гастрокухни. Для нераспознанного
/// типа — нейтральная иконка кухонного оборудования.
IconData iconForEquipmentType(String type) {
  final normalized = type.toLowerCase();
  bool has(String keyword) => normalized.contains(keyword);

  if (has('посудомо')) return Icons.local_laundry_service_outlined;
  if (has('холодильн') || has('морозил') || has('камера')) {
    return Icons.ac_unit_outlined;
  }
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
