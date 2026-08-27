import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/home/request_chat_screen.dart';
import 'features/splash/splash_video_screen.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/push_notification_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseService.initialize();
  await localeController.load();
  await PushNotificationService.instance.initializeApp();
  PushNotificationService.instance.listenForTaps();
  runApp(const ProjectServiceApp());
}

class ProjectServiceApp extends StatefulWidget {
  const ProjectServiceApp({super.key});

  @override
  State<ProjectServiceApp> createState() => _ProjectServiceAppState();
}

class _ProjectServiceAppState extends State<ProjectServiceApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Нажатие на push-уведомление о новом сообщении чата — открыть этот
    // чат поверх текущего экрана. Работает и на холодном старте (когда
    // именно нажатие на уведомление запустило приложение), и когда
    // приложение уже было открыто в фоне.
    PushNotificationService.instance.onNotificationTap.listen((message) {
      final requestId = message.data['requestId'];
      final title = message.data['title'];
      final otherPartyName = message.data['otherPartyName'];
      if (requestId == null || title == null || otherPartyName == null) {
        return;
      }
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => RequestChatScreen(
            requestId: requestId,
            title: title,
            otherPartyName: otherPartyName,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: localeController,
      builder: (context, locale, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
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
          home: const SplashVideoScreen(),
        );
      },
    );
  }
}
