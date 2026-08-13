import 'service_request.dart';

/// Заявка вместе с данными, которые обычной модели ServiceRequest не
/// нужны, но нужны для списка/детали: название и адрес заведения,
/// контакт клиента, человекочитаемые названия оборудования. Собирается
/// из одного запроса с embed-джойнами Supabase (см.
/// ServiceRequestRepository.fetchAll()) — используется и на экране
/// администратора (видит все заявки), и на экране клиента (видит только
/// заявки своего заведения, это фильтрует RLS на уровне базы).
class RequestListItem {
  final ServiceRequest request;
  final String establishmentName;
  final String? establishmentAddress;
  final String clientName;
  final String? clientPhone;
  final List<String> equipmentLabels;

  const RequestListItem({
    required this.request,
    required this.establishmentName,
    required this.clientName,
    required this.equipmentLabels,
    this.establishmentAddress,
    this.clientPhone,
  });

  factory RequestListItem.fromJson(Map<String, dynamic> json) {
    final establishment = json['establishments'] as Map<String, dynamic>?;
    final client = json['profiles'] as Map<String, dynamic>?;
    final equipmentLinks =
        json['service_request_equipment'] as List<dynamic>? ?? const [];

    return RequestListItem(
      request: ServiceRequest.fromJson(json),
      establishmentName: establishment?['name'] as String? ?? 'Заведение',
      establishmentAddress: establishment?['address'] as String?,
      clientName: client?['full_name'] as String? ?? 'Клиент',
      clientPhone: client?['phone'] as String?,
      equipmentLabels: equipmentLinks.map((link) {
        final equipment =
            (link as Map<String, dynamic>)['equipment'] as Map<String, dynamic>?;
        final type = equipment?['type'] as String? ?? 'Оборудование';
        final code = equipment?['sticker_code'] as String?;
        return code == null ? type : '$type · $code';
      }).toList(),
    );
  }
}
