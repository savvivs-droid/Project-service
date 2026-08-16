import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'device_token_repository.dart';

/// Push-уведомления (Firebase Cloud Messaging). Сама отправка — на
/// стороне сервера (Edge Function send-push-notification, вызывается
/// вебхуком на новое сообщение чата, см. supabase/functions); здесь —
/// только приём: инициализация Firebase, регистрация токена устройства
/// и обработка нажатия на уведомление (открыть нужный чат).
///
/// Только Android/iOS — сознательно не трогаем веб:
///   - firebase_core_web подгружает JS SDK Firebase с gstatic.com прямо
///     во время инициализации; если этот домен недоступен (блокировка
///     сети/оператора — см. похожую оговорку про CanvasKit в README),
///     приложение зависает на пустом экране ещё до входа. Это касалось
///     бы вообще всех, кто открывает веб-версию, не только тех, кому
///     нужны пуши.
///   - фоновый push в браузере в принципе требует отдельный Service
///     Worker (firebase-messaging-sw.js), а он у веб-сборки специально
///     отключён (см. историю веб-превью — "кэш всегда мешал").
///   - веб — это превью для стейкхолдеров (см. README), а не целевая
///     платформа приложения (iOS/Android).
class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  final _tokenRepository = DeviceTokenRepository();
  final _tapController = StreamController<RemoteMessage>.broadcast();

  String? _registeredToken;

  /// Данные уведомления, по которому нажали (и приложение было открыто
  /// или запущено этим нажатием) — requestId/title/otherPartyName в
  /// data-payload, см. Edge Function. Слушает main.dart, чтобы открыть
  /// нужный чат поверх текущего экрана.
  Stream<RemoteMessage> get onNotificationTap => _tapController.stream;

  Future<void> initializeApp() async {
    if (kIsWeb) return;
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  /// Вызывается, когда известен залогиненный пользователь (см.
  /// AuthGate) — просит разрешение на уведомления и заводит токен
  /// устройства. Молча ничего не делает при отказе — push-уведомления
  /// необязательны для работы приложения.
  Future<void> registerForCurrentUser() async {
    if (kIsWeb) return;

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await messaging.getToken();
    if (token != null) await _register(token);

    messaging.onTokenRefresh.listen(_register);
  }

  Future<void> _register(String token) async {
    _registeredToken = token;
    await _tokenRepository.upsert(token: token, platform: _platformName());
  }

  String _platformName() =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

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
    if (kIsWeb) return;
    FirebaseMessaging.onMessageOpenedApp.listen(_tapController.add);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _tapController.add(message);
    });
  }
}
