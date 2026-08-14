import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// Короткий доступ к переводам: `context.l10n.someKey` вместо
/// `AppLocalizations.of(context)!.someKey`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
