/// Мост к Web Push в браузере (web/push.js). На Android/iOS — заглушка:
/// там push идут через Firebase (см. PushNotificationService).
export 'web_push_bridge_stub.dart'
    if (dart.library.js_interop) 'web_push_bridge_web.dart';
