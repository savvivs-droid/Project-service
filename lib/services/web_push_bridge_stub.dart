/// Заглушка для Android/iOS — веб-push там не используется.
class WebPushBridge {
  static String status() => 'unsupported';

  static Future<String?> subscribe(String vapidPublicKey) async => null;

  static Future<String?> currentSubscription() async => null;
}
