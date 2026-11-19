import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/config/web_push_config.dart';
import '../core/l10n/locale_controller.dart';
import '../firebase_options.dart';
import 'device_token_repository.dart';
import 'web_push_bridge.dart';

/// Push-уведомления (Firebase Cloud Messaging). Сама отправка — на
/// стороне сервера (Edge Function send-push-notification, вызывается
/// вебхуком на новое сообщение чата, см. supabase/functions); здесь —
/// только приём: инициализация Firebase, регистрация токена устройства
/// и обработка нажатия на уведомление (открыть нужный чат).
///
/// Android/iOS — через Firebase. В браузере (веб-версия) Firebase
/// сознательно не используем: firebase_core_web грузит JS SDK с
/// gstatic.com, и при блокировке этого домена приложение зависало бы на
/// белом экране. Вместо этого — стандартный Web Push (web/push.js,
/// web/push-sw.js), подписка хранится в device_tokens с platform = 'web',
/// отправляют те же Edge Functions.
class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  final _tokenRepository = DeviceTokenRepository();
  // Нажатие могло прийти до того, как main.dart подписался (холодный
  // старт) — держим его и отдаём первому слушателю.
  final _pendingTaps = <Map<String, String>>[];
  late final _tapController = StreamController<Map<String, String>>.broadcast(
    onListen: () {
      final pending = List.of(_pendingTaps);
      _pendingTaps.clear();
      pending.forEach(_tapController.add);
    },
  );

  void _emitTap(Map<String, String> data) {
    if (_tapController.hasListener) {
      _tapController.add(data);
    } else {
      _pendingTaps.add(data);
    }
  }

  String? _registeredToken;

  /// Данные уведомления, по которому нажали (и приложение было открыто
  /// или запущено этим нажатием). Два вида data-payload:
  ///   - новое сообщение чата — requestId/title/otherPartyName
  ///     (send-push-notification);
  ///   - заявки — type: 'new_request' (администратору) или 'status'
  ///     (клиенту) + requestId (send-request-notification). Слушает main.dart, чтобы открыть
  /// нужный экран поверх текущего.
  Stream<Map<String, String>> get onNotificationTap => _tapController.stream;

  Future<void> initializeApp() async {
    if (kIsWeb) return;
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  /// Вызывается, когда известен залогиненный пользователь (см.
  /// AuthGate) — просит разрешение на уведомления и заводит токен
  /// устройства. Молча ничего не делает при отказе — push-уведомления
  /// необязательны для работы приложения.
  Future<void> registerForCurrentUser() async {
    if (kIsWeb) {
      // В браузере разрешение спрашиваем только по кнопке (баннер
      // WebPushBanner) — здесь лишь обновляем уже выданную подписку
      // (новый вход, другой пользователь на том же устройстве, язык).
      final subscription = await WebPushBridge.currentSubscription();
      if (subscription != null) await _register(subscription);
      _listenToLocale();
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await messaging.getToken();
    if (token != null) await _register(token);

    messaging.onTokenRefresh.listen(_register);

    _listenToLocale();
  }

  /// Состояние push в браузере: 'unsupported' | 'needs-install' |
  /// 'default' | 'granted' | 'denied' (см. web/push.js).
  String get webPushStatus => kIsWeb ? WebPushBridge.status() : 'unsupported';

  /// Включить push в веб-версии — вызывать по нажатию кнопки. true, если
  /// разрешение дано и подписка сохранена.
  Future<bool> enableWebPush() async {
    if (!kIsWeb) return false;
    final subscription = await WebPushBridge.subscribe(webPushVapidPublicKey);
    if (subscription == null) return false;
    await _register(subscription);
    _listenToLocale();
    return true;
  }

  // Сменили язык в приложении — сообщаем серверу, чтобы следующие
  // уведомления о статусе заявки пришли уже на новом языке.
  void _listenToLocale() {
    if (_listeningToLocale) return;
    _listeningToLocale = true;
    localeController.addListener(_onLocaleChanged);
  }

  bool _listeningToLocale = false;

  void _onLocaleChanged() {
    final token = _registeredToken;
    if (token != null) unawaited(_register(token));
  }

  Future<void> _register(String token) async {
    _registeredToken = token;
    await _tokenRepository.upsert(
      token: token,
      platform: _platformName(),
      locale: _currentLocaleCode(),
    );
  }

  /// Выбранный в приложении язык, а если "как в системе" — язык
  /// устройства, если он среди поддерживаемых (иначе чешский — так же,
  /// как выбирает Flutter по supportedLocales в main.dart).
  String _currentLocaleCode() {
    final chosen = localeController.value;
    if (chosen != null) return chosen.languageCode;
    final system = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final supported = LocaleController.supportedLocales
        .any((locale) => locale.languageCode == system);
    return supported ? system : LocaleController.supportedLocales.first.languageCode;
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  /// При выходе из аккаунта — иначе следующий, кто войдёт на этом же
  /// устройстве, продолжил бы получать чужие уведомления.
  Future<void> unregisterCurrentDevice() async {
    final token = _registeredToken;
    if (token == null) return;
    _registeredToken = null;
    await _tokenRepository.remove(token);
  }

  /// Один раз при старте приложения — не требует авторизации.
  void listenForTaps() {
    if (kIsWeb) {
      // Веб: данные нажатия передаёт web/push.js (из адреса при запуске
      // нажатием или сообщением service worker'а, если уже открыто).
      void addJson(String json) {
        try {
          final decoded = jsonDecode(json) as Map<String, dynamic>;
          _emitTap(decoded.map((key, value) => MapEntry(key, '$value')));
        } catch (_) {}
      }

      final pending = WebPushBridge.takeTap();
      if (pending != null) addJson(pending);
      WebPushBridge.onTap(addJson);
      return;
    }
    Map<String, String> dataOf(RemoteMessage message) =>
        message.data.map((key, value) => MapEntry(key, '$value'));
    FirebaseMessaging.onMessageOpenedApp
        .listen((message) => _emitTap(dataOf(message)));
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _emitTap(dataOf(message));
    });
  }
}
