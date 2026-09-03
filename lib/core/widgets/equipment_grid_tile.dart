import 'package:flutter/material.dart';

/// Плитка с иконкой-иллюстрацией, подписью и счётчиком — категория
/// оборудования, вид внутри категории. Общий виджет для ClientHomeScreen
/// (сетка категорий) и ClientEquipmentTypesScreen (сетка видов внутри
/// категории), чтобы обе сетки выглядели одинаково. Сетки используют
/// 2 колонки — крупные плитки с "иллюстрацией" (иконка на цветной
/// подложке-градиенте) вместо мелких иконок на белом фоне.
class EquipmentGridTile extends StatelessWidget {
  const EquipmentGridTile({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.illustration,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  /// Нарисованная от руки иллюстрация (см. equipment_illustrations.dart)
  /// — если задана, показывается вместо [icon]. Пока есть только для
  /// категорий верхнего уровня.
  final CustomPainter? illustration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.14),
                              colorScheme.secondary.withValues(alpha: 0.16),
                            ],
                          ),
                        ),
                        child: illustration != null
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CustomPaint(
                                  painter: illustration,
                                  child: const SizedBox.expand(),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  icon,
                                  size: 44,
                                  color: colorScheme.primary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
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
                      fontSize: 12,
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
