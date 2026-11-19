import 'package:flutter/material.dart';

/// Нижняя навигация вместо стандартного NavigationBar: подписи всегда
/// строго по центру под иконкой. У стандартного длинные подписи
/// ("Планировщик", "Выполненные") переносились посреди слова и
/// прижимались к левому краю. Здесь однословная подпись при нехватке
/// места чуть уменьшается, а подпись из нескольких слов переносится
/// по словам, по центру.
///
/// API как у NavigationBar — destinations те же NavigationDestination.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainer,
      elevation: 3,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _Item(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant;
    final label = destination.label;
    final style = (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
      fontSize: 11.5,
      height: 1.15,
      color: color,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    );

    final text = label.contains(' ')
        ? Text(
            label,
            style: style,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: style, maxLines: 1, textAlign: TextAlign.center),
          );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? colorScheme.secondaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: 24,
                    color: selected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                  ),
                  child: selected ? (destination.selectedIcon ?? destination.icon) : destination.icon,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(width: double.infinity, child: Center(child: text)),
            ],
          ),
        ),
      ),
    );
  }
}
