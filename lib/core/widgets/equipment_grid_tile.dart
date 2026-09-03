import 'package:flutter/material.dart';

/// Плитка с иконкой, подписью и счётчиком — категория оборудования,
/// вид внутри категории. Общий виджет для ClientHomeScreen (сетка
/// категорий) и ClientEquipmentTypesScreen (сетка видов внутри
/// категории), чтобы обе сетки выглядели одинаково.
class EquipmentGridTile extends StatelessWidget {
  const EquipmentGridTile({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Иконка и подпись раскладываются по фиксированным зонам
            // (а не центрируются как единый блок), иначе у подписей
            // на одну и две строки центр иконки съезжает по вертикали
            // и иконки в соседних плитках оказываются не на одном
            // уровне.
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Icon(icon, size: 30, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
            if (count > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
