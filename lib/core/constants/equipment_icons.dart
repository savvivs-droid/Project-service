import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

/// Категория оборудования — верхний уровень навигации ("Тепловое
/// оборудование", "Холодильное оборудование" и т. д.), внутри каждой —
/// конкретные виды техники ([EquipmentTypeKey]). Список категорий и их
/// состав зафиксированы (см. equipmentTypesForCategory) — по просьбе
/// администратора, чтобы список видов на экране не расползался.
enum EquipmentCategory {
  thermal,
  refrigeration,
  dishwashing,
  foodPrep,
  pizzaBakery,
  bar,
  water,
  other,
}

extension EquipmentCategoryX on EquipmentCategory {
  IconData get icon => switch (this) {
        EquipmentCategory.thermal => Icons.local_fire_department_outlined,
        EquipmentCategory.refrigeration => Icons.ac_unit_outlined,
        EquipmentCategory.dishwashing => Icons.local_laundry_service_outlined,
        EquipmentCategory.foodPrep => Icons.content_cut_outlined,
        EquipmentCategory.pizzaBakery => Icons.local_pizza_outlined,
        EquipmentCategory.bar => Icons.local_cafe_outlined,
        EquipmentCategory.water => Icons.water_drop_outlined,
        EquipmentCategory.other => Icons.more_horiz,
      };

  /// Настоящее фото прибора для плитки категории — если задано,
  /// показывается вместо нарисованной иллюстрации (см.
  /// equipment_illustrations.dart). Пока есть не для всех категорий —
  /// остальные показывают иллюстрацию, пока не появится фото.
  String? get photoAsset => switch (this) {
        EquipmentCategory.thermal =>
          'assets/equipment_categories/thermal.jpg',
        EquipmentCategory.refrigeration =>
          'assets/equipment_categories/refrigeration.jpg',
        EquipmentCategory.dishwashing =>
          'assets/equipment_categories/dishwashing.jpg',
        EquipmentCategory.foodPrep =>
          'assets/equipment_categories/food_prep.jpg',
        EquipmentCategory.pizzaBakery =>
          'assets/equipment_categories/pizza_bakery.jpg',
        EquipmentCategory.bar => 'assets/equipment_categories/bar.jpg',
        EquipmentCategory.water => 'assets/equipment_categories/water.jpg',
        EquipmentCategory.other => 'assets/equipment_categories/other.jpg',
      };

  String label(BuildContext context) => switch (this) {
        EquipmentCategory.thermal => context.l10n.equipmentCategoryThermal,
        EquipmentCategory.refrigeration =>
          context.l10n.equipmentCategoryRefrigeration,
        EquipmentCategory.dishwashing =>
          context.l10n.equipmentCategoryDishwashing,
        EquipmentCategory.foodPrep => context.l10n.equipmentCategoryFoodPrep,
        EquipmentCategory.pizzaBakery =>
          context.l10n.equipmentCategoryPizzaBakery,
        EquipmentCategory.bar => context.l10n.equipmentCategoryBar,
        EquipmentCategory.water => context.l10n.equipmentCategoryWater,
        // Та же подпись, что и у "свободного" типа внутри категории —
        // это по сути одно и то же понятие на двух уровнях навигации.
        EquipmentCategory.other => context.l10n.equipmentTypeOther,
      };
}

/// Стабильный, независимый от языка идентификатор вида оборудования.
/// Именно [storageValue] сохраняется в БД (equipment.type) — не
/// локализованное название, иначе один и тот же холодильник назывался
/// бы по-разному в зависимости от того, на каком языке интерфейса его
/// когда-то добавили. Отображаемое название — всегда через
/// [EquipmentTypeKeyX.label], по текущему языку приложения.
///
/// [cuttingTable] — из старой плоской версии списка (до разбивки на
/// категории), в новый список видов не входит и в форме выбора не
/// предлагается, но распознаётся у уже существующих записей, чтобы не
/// потерять иконку/название.
enum EquipmentTypeKey {
  // Тепловое оборудование
  combiOven,
  oven,
  stove,
  fryer,
  grill,
  salamander,
  bainMarie,
  microwave,
  // Холодильное оборудование
  fridge,
  freezer,
  coldTable,
  displayCase,
  blastChiller,
  // Посудомоечное оборудование
  dishwasher,
  glasswasher,
  hoodDishwasher,
  conveyorDishwasher,
  // Оборудование для обработки продуктов
  meatGrinder,
  slicer,
  vegetableCutter,
  cutter,
  mixer,
  blender,
  // Пицца и пекарня
  pizzaOven,
  doughMixer,
  doughSheeter,
  provingCabinet,
  // Бар и напитки
  coffeeMachine,
  coffeeGrinder,
  iceMaker,
  drinkCooler,
  postMix,
  // Вода и водоподготовка
  waterSoftener,
  waterFilter,
  pump,
  reverseOsmosis,
  // Legacy — см. комментарий к enum выше
  cuttingTable,
}

extension EquipmentTypeKeyX on EquipmentTypeKey {
  EquipmentCategory get category => switch (this) {
        EquipmentTypeKey.combiOven ||
        EquipmentTypeKey.oven ||
        EquipmentTypeKey.stove ||
        EquipmentTypeKey.fryer ||
        EquipmentTypeKey.grill ||
        EquipmentTypeKey.salamander ||
        EquipmentTypeKey.bainMarie ||
        EquipmentTypeKey.microwave =>
          EquipmentCategory.thermal,
        EquipmentTypeKey.fridge ||
        EquipmentTypeKey.freezer ||
        EquipmentTypeKey.coldTable ||
        EquipmentTypeKey.displayCase ||
        EquipmentTypeKey.blastChiller =>
          EquipmentCategory.refrigeration,
        EquipmentTypeKey.dishwasher ||
        EquipmentTypeKey.glasswasher ||
        EquipmentTypeKey.hoodDishwasher ||
        EquipmentTypeKey.conveyorDishwasher =>
          EquipmentCategory.dishwashing,
        EquipmentTypeKey.meatGrinder ||
        EquipmentTypeKey.slicer ||
        EquipmentTypeKey.vegetableCutter ||
        EquipmentTypeKey.cutter ||
        EquipmentTypeKey.mixer ||
        EquipmentTypeKey.blender ||
        // Legacy-тип — считаем частью той же категории для группировки
        // (сам в списке видов на выбор не появляется).
        EquipmentTypeKey.cuttingTable =>
          EquipmentCategory.foodPrep,
        EquipmentTypeKey.pizzaOven ||
        EquipmentTypeKey.doughMixer ||
        EquipmentTypeKey.doughSheeter ||
        EquipmentTypeKey.provingCabinet =>
          EquipmentCategory.pizzaBakery,
        EquipmentTypeKey.coffeeMachine ||
        EquipmentTypeKey.coffeeGrinder ||
        EquipmentTypeKey.iceMaker ||
        EquipmentTypeKey.drinkCooler ||
        EquipmentTypeKey.postMix =>
          EquipmentCategory.bar,
        EquipmentTypeKey.waterSoftener ||
        EquipmentTypeKey.waterFilter ||
        EquipmentTypeKey.pump ||
        EquipmentTypeKey.reverseOsmosis =>
          EquipmentCategory.water,
      };

  String get storageValue => switch (this) {
        EquipmentTypeKey.combiOven => 'combi_oven',
        EquipmentTypeKey.oven => 'oven',
        EquipmentTypeKey.stove => 'stove',
        EquipmentTypeKey.fryer => 'fryer',
        EquipmentTypeKey.grill => 'grill',
        EquipmentTypeKey.salamander => 'salamander',
        EquipmentTypeKey.bainMarie => 'bain_marie',
        EquipmentTypeKey.microwave => 'microwave',
        EquipmentTypeKey.fridge => 'fridge',
        EquipmentTypeKey.freezer => 'freezer',
        EquipmentTypeKey.coldTable => 'cold_table',
        EquipmentTypeKey.displayCase => 'display_case',
        EquipmentTypeKey.blastChiller => 'blast_chiller',
        EquipmentTypeKey.dishwasher => 'dishwasher',
        EquipmentTypeKey.glasswasher => 'glasswasher',
        EquipmentTypeKey.hoodDishwasher => 'hood_dishwasher',
        EquipmentTypeKey.conveyorDishwasher => 'conveyor_dishwasher',
        EquipmentTypeKey.meatGrinder => 'meat_grinder',
        EquipmentTypeKey.slicer => 'slicer',
        EquipmentTypeKey.vegetableCutter => 'vegetable_cutter',
        EquipmentTypeKey.cutter => 'cutter',
        EquipmentTypeKey.mixer => 'mixer',
        EquipmentTypeKey.blender => 'blender',
        EquipmentTypeKey.pizzaOven => 'pizza_oven',
        EquipmentTypeKey.doughMixer => 'dough_mixer',
        EquipmentTypeKey.doughSheeter => 'dough_sheeter',
        EquipmentTypeKey.provingCabinet => 'proving_cabinet',
        EquipmentTypeKey.coffeeMachine => 'coffee_machine',
        EquipmentTypeKey.coffeeGrinder => 'coffee_grinder',
        EquipmentTypeKey.iceMaker => 'ice_maker',
        EquipmentTypeKey.drinkCooler => 'drink_cooler',
        EquipmentTypeKey.postMix => 'post_mix',
        EquipmentTypeKey.waterSoftener => 'water_softener',
        EquipmentTypeKey.waterFilter => 'water_filter',
        EquipmentTypeKey.pump => 'pump',
        EquipmentTypeKey.reverseOsmosis => 'reverse_osmosis',
        EquipmentTypeKey.cuttingTable => 'cutting_table',
      };

  IconData get icon => switch (this) {
        EquipmentTypeKey.combiOven => Icons.local_dining_outlined,
        EquipmentTypeKey.oven => Icons.fireplace_outlined,
        EquipmentTypeKey.stove => Icons.local_fire_department_outlined,
        EquipmentTypeKey.fryer => Icons.ramen_dining_outlined,
        EquipmentTypeKey.grill => Icons.outdoor_grill_outlined,
        EquipmentTypeKey.salamander => Icons.wb_sunny_outlined,
        EquipmentTypeKey.bainMarie => Icons.soup_kitchen_outlined,
        EquipmentTypeKey.microwave => Icons.microwave_outlined,
        EquipmentTypeKey.fridge => Icons.ac_unit_outlined,
        EquipmentTypeKey.freezer => Icons.severe_cold_outlined,
        EquipmentTypeKey.coldTable => Icons.table_restaurant_outlined,
        EquipmentTypeKey.displayCase => Icons.storefront_outlined,
        EquipmentTypeKey.blastChiller => Icons.thermostat_outlined,
        EquipmentTypeKey.dishwasher => Icons.local_laundry_service_outlined,
        EquipmentTypeKey.glasswasher => Icons.local_bar_outlined,
        EquipmentTypeKey.hoodDishwasher => Icons.expand_less_outlined,
        EquipmentTypeKey.conveyorDishwasher => Icons.moving_outlined,
        EquipmentTypeKey.meatGrinder => Icons.kebab_dining_outlined,
        EquipmentTypeKey.slicer => Icons.content_cut_outlined,
        EquipmentTypeKey.vegetableCutter => Icons.eco_outlined,
        EquipmentTypeKey.cutter => Icons.change_circle_outlined,
        EquipmentTypeKey.mixer => Icons.blender_outlined,
        EquipmentTypeKey.blender => Icons.local_drink_outlined,
        EquipmentTypeKey.pizzaOven => Icons.local_pizza_outlined,
        EquipmentTypeKey.doughMixer => Icons.bakery_dining_outlined,
        EquipmentTypeKey.doughSheeter => Icons.crop_7_5_outlined,
        EquipmentTypeKey.provingCabinet => Icons.inventory_2_outlined,
        EquipmentTypeKey.coffeeMachine => Icons.coffee_maker_outlined,
        EquipmentTypeKey.coffeeGrinder => Icons.coffee_outlined,
        EquipmentTypeKey.iceMaker => Icons.icecream_outlined,
        EquipmentTypeKey.drinkCooler => Icons.kitchen_outlined,
        EquipmentTypeKey.postMix => Icons.bubble_chart_outlined,
        EquipmentTypeKey.waterSoftener => Icons.water_drop_outlined,
        EquipmentTypeKey.waterFilter => Icons.filter_alt_outlined,
        EquipmentTypeKey.pump => Icons.plumbing_outlined,
        EquipmentTypeKey.reverseOsmosis => Icons.compress_outlined,
        EquipmentTypeKey.cuttingTable => Icons.countertops_outlined,
      };

  /// Настоящее фото прибора для плитки вида оборудования — если
  /// задано, показывается вместо иконки (см. EquipmentGridTile). Пока
  /// есть не для всех видов — остальные показывают иконку.
  String? get photoAsset => switch (this) {
        // Тот же снимок, что и на плитке категории "Тепловое
        // оборудование" — отдельного фото для конвектомата не было.
        EquipmentTypeKey.combiOven => 'assets/equipment_categories/thermal.jpg',
        EquipmentTypeKey.oven => 'assets/equipment_types/oven.jpg',
        EquipmentTypeKey.stove => 'assets/equipment_types/stove.jpg',
        EquipmentTypeKey.fryer => 'assets/equipment_types/fryer.jpg',
        EquipmentTypeKey.grill => 'assets/equipment_types/grill.jpg',
        EquipmentTypeKey.salamander => 'assets/equipment_types/salamander.jpg',
        EquipmentTypeKey.bainMarie => 'assets/equipment_types/bain_marie.jpg',
        EquipmentTypeKey.microwave => 'assets/equipment_types/microwave.jpg',
        // Тот же снимок, что и на плитке категории "Холодильное
        // оборудование" — отдельного фото для холодильника не было.
        EquipmentTypeKey.fridge => 'assets/equipment_categories/refrigeration.jpg',
        EquipmentTypeKey.freezer => 'assets/equipment_types/freezer.jpg',
        EquipmentTypeKey.coldTable => 'assets/equipment_types/cold_table.jpg',
        EquipmentTypeKey.displayCase => 'assets/equipment_types/display_case.jpg',
        EquipmentTypeKey.blastChiller =>
          'assets/equipment_types/blast_chiller.jpg',
        // Тот же снимок, что и на плитке категории "Посудомоечное
        // оборудование" — отдельного фото для обычной посудомойки не
        // присылали.
        EquipmentTypeKey.dishwasher =>
          'assets/equipment_categories/dishwashing.jpg',
        EquipmentTypeKey.glasswasher => 'assets/equipment_types/glasswasher.jpg',
        EquipmentTypeKey.hoodDishwasher =>
          'assets/equipment_types/hood_dishwasher.jpg',
        EquipmentTypeKey.conveyorDishwasher =>
          'assets/equipment_types/conveyor_dishwasher.jpg',
        _ => null,
      };

  String label(BuildContext context) => switch (this) {
        EquipmentTypeKey.combiOven => context.l10n.equipmentTypeCombiOven,
        EquipmentTypeKey.oven => context.l10n.equipmentTypeOven,
        EquipmentTypeKey.stove => context.l10n.equipmentTypeStove,
        EquipmentTypeKey.fryer => context.l10n.equipmentTypeFryer,
        EquipmentTypeKey.grill => context.l10n.equipmentTypeGrill,
        EquipmentTypeKey.salamander => context.l10n.equipmentTypeSalamander,
        EquipmentTypeKey.bainMarie => context.l10n.equipmentTypeBainMarie,
        EquipmentTypeKey.microwave => context.l10n.equipmentTypeMicrowave,
        EquipmentTypeKey.fridge => context.l10n.equipmentTypeFridge,
        EquipmentTypeKey.freezer => context.l10n.equipmentTypeFreezer,
        EquipmentTypeKey.coldTable => context.l10n.equipmentTypeColdTable,
        EquipmentTypeKey.displayCase => context.l10n.equipmentTypeDisplayCase,
        EquipmentTypeKey.blastChiller =>
          context.l10n.equipmentTypeBlastChiller,
        EquipmentTypeKey.dishwasher => context.l10n.equipmentTypeDishwasher,
        EquipmentTypeKey.glasswasher => context.l10n.equipmentTypeGlasswasher,
        EquipmentTypeKey.hoodDishwasher =>
          context.l10n.equipmentTypeHoodDishwasher,
        EquipmentTypeKey.conveyorDishwasher =>
          context.l10n.equipmentTypeConveyorDishwasher,
        EquipmentTypeKey.meatGrinder => context.l10n.equipmentTypeMeatGrinder,
        EquipmentTypeKey.slicer => context.l10n.equipmentTypeSlicer,
        EquipmentTypeKey.vegetableCutter =>
          context.l10n.equipmentTypeVegetableCutter,
        EquipmentTypeKey.cutter => context.l10n.equipmentTypeCutter,
        EquipmentTypeKey.mixer => context.l10n.equipmentTypeMixer,
        EquipmentTypeKey.blender => context.l10n.equipmentTypeBlender,
        EquipmentTypeKey.pizzaOven => context.l10n.equipmentTypePizzaOven,
        EquipmentTypeKey.doughMixer => context.l10n.equipmentTypeDoughMixer,
        EquipmentTypeKey.doughSheeter =>
          context.l10n.equipmentTypeDoughSheeter,
        EquipmentTypeKey.provingCabinet =>
          context.l10n.equipmentTypeProvingCabinet,
        EquipmentTypeKey.coffeeMachine =>
          context.l10n.equipmentTypeCoffeeMachine,
        EquipmentTypeKey.coffeeGrinder =>
          context.l10n.equipmentTypeCoffeeGrinder,
        EquipmentTypeKey.iceMaker => context.l10n.equipmentTypeIceMaker,
        EquipmentTypeKey.drinkCooler => context.l10n.equipmentTypeDrinkCooler,
        EquipmentTypeKey.postMix => context.l10n.equipmentTypePostMix,
        EquipmentTypeKey.waterSoftener =>
          context.l10n.equipmentTypeWaterSoftener,
        EquipmentTypeKey.waterFilter => context.l10n.equipmentTypeWaterFilter,
        EquipmentTypeKey.pump => context.l10n.equipmentTypePump,
        EquipmentTypeKey.reverseOsmosis =>
          context.l10n.equipmentTypeReverseOsmosis,
        EquipmentTypeKey.cuttingTable =>
          context.l10n.equipmentTypeCuttingTable,
      };
}

/// Виды оборудования, которые предлагаются на выбор внутри категории
/// (экран видов и форма добавления/редактирования) — без legacy-типов
/// вроде [EquipmentTypeKey.cuttingTable], которые остаются только для
/// отображения уже существующих записей.
List<EquipmentTypeKey> equipmentTypesForCategory(EquipmentCategory category) {
  return EquipmentTypeKey.values
      .where((key) => key.category == category && key != EquipmentTypeKey.cuttingTable)
      .toList();
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
