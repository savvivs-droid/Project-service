import 'package:url_launcher/url_launcher.dart';

/// Открывает номер [phone] в звонилке устройства.
Future<bool> launchPhoneCall(String phone) async {
  final sanitized = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (sanitized.isEmpty) return false;
  final uri = Uri(scheme: 'tel', path: sanitized);
  return launchUrl(uri);
}

/// Открывает [address] в Google Maps (в приложении, если оно установлено,
/// иначе в браузере) — универсальная ссылка работает на iOS и Android.
Future<bool> launchMapsSearch(String address) async {
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': address,
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
