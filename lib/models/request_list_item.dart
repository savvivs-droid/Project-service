import 'package:flutter/widgets.dart';

import '../core/constants/equipment_icons.dart';
import 'service_request.dart';

/// Единица оборудования, привязанная к заявке — храним сырые данные
/// (не готовую строку), потому что тип нужно локализовать при показе,
/// а во время разбора JSON (фабрика ниже) BuildContext ещё недоступен.
class EquipmentRef {
  final String type;
  final String? stickerCode;

  const EquipmentRef({required this.type, this.stickerCode});

  /// Локализованное название типа, с кодом стикера через " · ", если он есть.
  String label(BuildContext context) {
    final typeLabel = equipmentTypeLabel(context, type);
    return stickerCode == null ? typeLabel : '$typeLabel · $stickerCode';
  }
}

/// Заявка вместе с данными, которые обычной модели ServiceRequest не
/// нужны, но нужны для списка/детали: название и адрес заведения,
/// контакт клиента, оборудование. Собирается из одного запроса с
/// embed-джойнами Supabase (см. ServiceRequestRepository.fetchAll()) —
/// используется и на экране администратора (видит все заявки), и на
/// экране клиента (видит только заявки своего заведения, это фильтрует
/// RLS на уровне базы).
class RequestListItem {
  final ServiceRequest request;
  final String establishmentName;
  final String? establishmentAddress;
  final String clientName;
  final String? clientPhone;
  final List<EquipmentRef> equipmentRefs;

  const RequestListItem({
    required this.request,
    required this.establishmentName,
    required this.clientName,
    required this.equipmentRefs,
    this.establishmentAddress,
    this.clientPhone,
  });

  factory RequestListItem.fromJson(Map<String, dynamic> json) {
    final establishment = json['establishments'] as Map<String, dynamic>?;
    final client = json['profiles'] as Map<String, dynamic>?;
    final equipmentLinks =
        json['service_request_equipment'] as List<dynamic>? ?? const [];

    // Эти строки парсят JSON вне дерева виджетов (нет BuildContext, а
    // значит и локали), а пустыми они практически не бывают — это
    // подстраховка на случай неполных данных, а не текст интерфейса,
    // поэтому используем нейтральный прочерк, а не слово на одном языке.
    return RequestListItem(
      request: ServiceRequest.fromJson(json),
      establishmentName: establishment?['name'] as String? ?? '—',
      establishmentAddress: establishment?['address'] as String?,
      clientName: client?['full_name'] as String? ?? '—',
      clientPhone: client?['phone'] as String?,
      equipmentRefs: equipmentLinks.map((link) {
        final equipment =
            (link as Map<String, dynamic>)['equipment'] as Map<String, dynamic>?;
        return EquipmentRef(
          type: equipment?['type'] as String? ?? '—',
          stickerCode: equipment?['sticker_code'] as String?,
        );
      }).toList(),
    );
  }
}
