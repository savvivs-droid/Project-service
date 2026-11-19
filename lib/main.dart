import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/home/admin_request_detail_screen.dart';
import 'features/home/client_request_detail_screen.dart';
import 'features/home/request_chat_screen.dart';
import 'features/splash/splash_video_screen.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/push_notification_service.dart';
import 'services/service_request_repository.dart';
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
    // Нажатие на push-уведомление: о новом сообщении чата — открыть этот
    // чат, о новой заявке или смене статуса — карточку заявки, поверх
    // текущего экрана. Работает и на холодном старте (когда
    // именно нажатие на уведомление запустило приложение), и когда
    // приложение уже было открыто в фоне.
    PushNotificationService.instance.onNotificationTap.listen(_handleTap);
  }

  /// Ждёт, пока приложение готово показать экран: есть навигатор и вход
  /// выполнен (при запуске нажатием на уведомление сначала идёт заставка и
  /// восстановление сессии). Не дождались за 20 с — false.
  Future<bool> _whenReady() async {
    for (var i = 0; i < 40; i++) {
      final ready = _navigatorKey.currentState != null &&
          SupabaseService.client.auth.currentSession != null;
      if (ready) {
        // Даём главному экрану встать под открываемый экран.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  Future<void> _handleTap(Map<String, String> data) async {
    final requestId = data['requestId'];
    if (requestId == null || !await _whenReady()) return;

    final type = data['type'];
    if (type == 'status' || type == 'new_request') {
      await _openRequestDetail(requestId, asAdmin: type == 'new_request');
      return;
    }

    // Сообщение в чате.
    final title = data['title'];
    final otherPartyName = data['otherPartyName'];
    if (title == null || otherPartyName == null) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => RequestChatScreen(
          requestId: requestId,
          title: title,
          otherPartyName: otherPartyName,
        ),
      ),
    );
  }

  /// Нажатие на push по заявке — открыть её карточку: администратору
  /// (новая заявка) — экран администратора, клиенту (смена статуса) —
  /// клиентский.
  Future<void> _openRequestDetail(
    String requestId, {
    required bool asAdmin,
  }) async {
    try {
      final item = await ServiceRequestRepository().fetchById(requestId);
      if (item == null) return;
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => asAdmin
              ? AdminRequestDetailScreen(item: item)
              : ClientRequestDetailScreen(item: item),
        ),
      );
    } catch (error) {
      debugPrint('Не удалось открыть заявку из уведомления: $error');
    }
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
