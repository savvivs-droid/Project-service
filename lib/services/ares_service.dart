import 'dart:convert';

import 'package:http/http.dart' as http;

/// Данные организации, полученные из чешского реестра ARES по IČO.
class AresCompanyInfo {
  final String name;
  final String? address;

  const AresCompanyInfo({required this.name, this.address});
}

/// Запрос к открытому REST API ARES (ares.gov.cz) — реестру экономических
/// субъектов Чехии. Ключ не нужен, запрос анонимный.
class AresService {
  static Uri _uri(String ico) => Uri.parse(
        'https://ares.gov.cz/ekonomicke-subjekty-v-be/rest/ekonomicke-subjekty/$ico',
      );

  /// Возвращает данные организации или null, если IČO не найден в реестре
  /// либо сервис недоступен. Ошибки намеренно проглатываются — автозаполнение
  /// не должно блокировать регистрацию, при неудаче просто заполняют вручную.
  static Future<AresCompanyInfo?> lookupByIco(String ico) async {
    try {
      final response = await http.get(_uri(ico)).timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode != 200) return null;

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final name = data['obchodniJmeno'] as String?;
      if (name == null || name.isEmpty) return null;

      final sidlo = data['sidlo'] as Map<String, dynamic>?;
      final address = sidlo?['textovaAdresa'] as String?;

      return AresCompanyInfo(name: name, address: address);
    } catch (_) {
      return null;
    }
  }
}
