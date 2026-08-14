import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

/// Стабильный, независимый от языка идентификатор типа оборудования.
/// Именно [storageValue] сохраняется в БД (equipment.type) — не
/// локализованное название, иначе один и тот же холодильник назывался
/// бы по-разному в зависимости от того, на каком языке интерфейса его
/// когда-то добавили. Отображаемое название — всегда через
/// [EquipmentTypeKeyX.label], по текущему языку приложения.
enum EquipmentTypeKey {
  fridge,
  freezer,
  combiOven,
  stove,
  dishwasher,
  grill,
  coffeeMachine,
  mixer,
  cuttingTable,
}

extension EquipmentTypeKeyX on EquipmentTypeKey {
  String get storageValue => switch (this) {
        EquipmentTypeKey.fridge => 'fridge',
        EquipmentTypeKey.freezer => 'freezer',
        EquipmentTypeKey.combiOven => 'combi_oven',
        EquipmentTypeKey.stove => 'stove',
        EquipmentTypeKey.dishwasher => 'dishwasher',
        EquipmentTypeKey.grill => 'grill',
        EquipmentTypeKey.coffeeMachine => 'coffee_machine',
        EquipmentTypeKey.mixer => 'mixer',
        EquipmentTypeKey.cuttingTable => 'cutting_table',
      };

  IconData get icon => switch (this) {
        EquipmentTypeKey.fridge => Icons.ac_unit_outlined,
        EquipmentTypeKey.freezer => Icons.severe_cold_outlined,
        EquipmentTypeKey.combiOven => Icons.microwave_outlined,
        EquipmentTypeKey.stove => Icons.local_fire_department_outlined,
        EquipmentTypeKey.dishwasher => Icons.local_laundry_service_outlined,
        EquipmentTypeKey.grill => Icons.outdoor_grill_outlined,
        EquipmentTypeKey.coffeeMachine => Icons.coffee_maker_outlined,
        EquipmentTypeKey.mixer => Icons.blender_outlined,
        EquipmentTypeKey.cuttingTable => Icons.countertops_outlined,
      };

  String label(BuildContext context) => switch (this) {
        EquipmentTypeKey.fridge => context.l10n.equipmentTypeFridge,
        EquipmentTypeKey.freezer => context.l10n.equipmentTypeFreezer,
        EquipmentTypeKey.combiOven => context.l10n.equipmentTypeCombiOven,
        EquipmentTypeKey.stove => context.l10n.equipmentTypeStove,
        EquipmentTypeKey.dishwasher => context.l10n.equipmentTypeDishwasher,
        EquipmentTypeKey.grill => context.l10n.equipmentTypeGrill,
        EquipmentTypeKey.coffeeMachine =>
          context.l10n.equipmentTypeCoffeeMachine,
        EquipmentTypeKey.mixer => context.l10n.equipmentTypeMixer,
        EquipmentTypeKey.cuttingTable =>
          context.l10n.equipmentTypeCuttingTable,
      };
}

/// Записи, добавленные до многоязычности, хранят тип обычным русским
/// текстом — распознаём и его, чтобы у уже существующего оборудования
/// не пропали иконка и понятное название. При следующем сохранении
/// такой записи тип автоматически перезапишется стабильным ключом (см.
/// EquipmentFormScreen), так что база сама "самолечится" по мере правок.
const _legacyRussianLabels = {
  'Холодильник': EquipmentTypeKey.fridge,
  'Морозильная камера': EquipmentTypeKey.freezer,
  'Пароконвектомат': EquipmentTypeKey.combiOven,
  'Плита': EquipmentTypeKey.stove,
  'Посудомоечная машина': EquipmentTypeKey.dishwasher,
  'Гриль': EquipmentTypeKey.grill,
  'Кофемашина': EquipmentTypeKey.coffeeMachine,
  'Миксер/блендер': EquipmentTypeKey.mixer,
  'Разделочный стол': EquipmentTypeKey.cuttingTable,
};

/// Определяет ключ типа по значению из БД — новому ([storageValue]) или
/// старому (русский текст). null означает свободный текст ("Другое") —
/// такое показываем как есть, переводить нечего, это не наш словарь.
EquipmentTypeKey? equipmentTypeKeyFromStorage(String value) {
  for (final key in EquipmentTypeKey.values) {
    if (key.storageValue == value) return key;
  }
  return _legacyRussianLabels[value];
}

/// Локализованное название типа оборудования для отображения.
String equipmentTypeLabel(BuildContext context, String storedType) {
  final key = equipmentTypeKeyFromStorage(storedType);
  return key == null ? storedType : key.label(context);
}

/// Иконка по значению из БД. Для нераспознанного (свободного) типа —
/// нейтральная иконка.
IconData equipmentTypeIcon(String storedType) {
  return equipmentTypeKeyFromStorage(storedType)?.icon ?? Icons.kitchen_outlined;
}
