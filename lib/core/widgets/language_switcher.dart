import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../l10n/locale_controller.dart';

/// Названия языков даны на них самих (эндонимы) — их не переводят,
/// как и "Deutsch" не становится "German" в немецкой версии приложения.
const _nativeNames = {
  'cs': 'Čeština',
  'en': 'English',
  'ru': 'Русский',
  'vi': 'Tiếng Việt',
};

/// Переключатель языка интерфейса — стоит в шапке каждого экрана.
/// Выбор сохраняется между запусками (см. LocaleController); пункт
/// "как в системе" сбрасывает ручной выбор и возвращает автоопределение.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final current = localeController.value;

    return PopupMenuButton<Locale?>(
      icon: const Icon(Icons.language),
      tooltip: context.l10n.languageSwitcherTooltip,
      onSelected: localeController.setLocale,
      itemBuilder: (context) => [
        for (final locale in LocaleController.supportedLocales)
          CheckedPopupMenuItem(
            value: locale,
            checked: current?.languageCode == locale.languageCode,
            child: Text(_nativeNames[locale.languageCode]!),
          ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: null,
          checked: current == null,
          child: Text(context.l10n.systemLanguageOption),
        ),
      ],
    );
  }
}
