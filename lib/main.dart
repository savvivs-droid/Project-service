import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseService.initialize();
  await localeController.load();
  runApp(const ProjectServiceApp());
}

class ProjectServiceApp extends StatelessWidget {
  const ProjectServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: localeController,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'FixMyGastro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          // null — язык определяется автоматически по настройкам
          // устройства (см. LocaleController); иначе — то, что выбрали
          // вручную через LanguageSwitcher, независимо от системы.
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Чешский — язык по умолчанию: первый в списке, на него
          // попадают, если язык устройства не входит в поддерживаемые.
          supportedLocales: LocaleController.supportedLocales,
          home: const AuthGate(),
        );
      },
    );
  }
}
