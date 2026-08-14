import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseService.initialize();
  runApp(const ProjectServiceApp());
}

class ProjectServiceApp extends StatelessWidget {
  const ProjectServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixMyGastro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Чешский — язык по умолчанию (первый в списке — на него попадают,
      // если язык устройства не входит в поддерживаемые); дальше язык
      // подхватывается автоматически из настроек устройства.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('cs'),
        Locale('en'),
        Locale('ru'),
        Locale('vi'),
      ],
      home: const AuthGate(),
    );
  }
}
