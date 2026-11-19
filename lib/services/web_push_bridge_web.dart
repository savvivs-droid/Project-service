import 'dart:js_interop';

@JS('fmgPush.status')
external JSString _status();

@JS('fmgPush.subscribe')
external JSPromise<JSString?> _subscribe(JSString vapidPublicKey);

@JS('fmgPush.currentSubscription')
external JSPromise<JSString?> _currentSubscription();

@JS('fmgPush.takeTap')
external JSString? _takeTap();

@JS('fmgPush.onTap')
external void _onTap(JSFunction callback);

/// Web Push в браузере — обёртка над window.fmgPush из web/push.js.
/// Если скрипт не загрузился, всё молча считается "не поддерживается".
class WebPushBridge {
  /// 'unsupported' | 'needs-install' | 'default' | 'granted' | 'denied'
  static String status() {
    try {
      return _status().toDart;
    } catch (_) {
      return 'unsupported';
    }
  }

  /// Должен вызываться по нажатию кнопки — иначе iPhone не покажет
  /// запрос разрешения. Возвращает подписку (JSON) или null.
  static Future<String?> subscribe(String vapidPublicKey) async {
    try {
      final result = await _subscribe(vapidPublicKey.toJS).toDart;
      return result?.toDart;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> currentSubscription() async {
    try {
      final result = await _currentSubscription().toDart;
      return result?.toDart;
    } catch (_) {
      return null;
    }
  }

  /// Нажатие на уведомление, которым запустили приложение (JSON data или
  /// null) — отдаётся один раз.
  static String? takeTap() {
    try {
      return _takeTap()?.toDart;
    } catch (_) {
      return null;
    }
  }

  /// Нажатия на уведомление, пока приложение открыто.
  static void onTap(void Function(String json) callback) {
    try {
      _onTap(((JSString json) => callback(json.toDart)).toJS);
    } catch (_) {}
  }
}
