/// Заглушка для Android/iOS — веб-push там не используется.
class WebPushBridge {
  static String status() => 'unsupported';

  static Future<String?> subscribe(String vapidPublicKey) async => null;

  static Future<String?> currentSubscription() async => null;

  static String? takeTap() => null;

  static void onTap(void Function(String json) callback) {}
}
