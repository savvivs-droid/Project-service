import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/request_list_item.dart';
import '../models/service_request.dart';
import 'supabase_service.dart';

class ServiceRequestRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Заявки, видимые текущему пользователю. Один и тот же запрос — RLS
  /// на уровне базы сам решает, что вернуть: администратору видны все
  /// заявки, клиенту — заявки заведений, где он состоит (см.
  /// establishment_members в supabase/schema.sql). [establishmentId] —
  /// дополнительный фильтр поверх этого для клиента с несколькими
  /// заведениями: сузить список до одного выбранного в переключателе.
  Future<List<RequestListItem>> fetchAll({String? establishmentId}) async {
    // profiles!service_requests_client_id_fkey — с появлением
    // request_read_state у PostgREST стало два пути от service_requests
    // к profiles (через client_id и через отметки прочтения), поэтому
    // нужную связь приходится называть явно, иначе embed падает с
    // PGRST201 "more than one relationship was found".
    final query = _client.from('service_requests').select(
          '*, establishments(name, address), '
          'profiles!service_requests_client_id_fkey(full_name, phone), '
          'service_request_equipment(equipment(type, sticker_code))',
        );

    final filtered = establishmentId == null
        ? query
        : query.eq('establishment_id', establishmentId);

    final data = await filtered.order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => RequestListItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Создаёт заявку от имени клиента и привязывает к ней выбранное
  /// оборудование через связующую таблицу service_request_equipment.
  Future<void> create({
    required String establishmentId,
    required String clientId,
    required String description,
    required List<String> equipmentIds,
  }) async {
    final row = await _client
        .from('service_requests')
        .insert({
          'establishment_id': establishmentId,
          'client_id': clientId,
          'description': description,
        })
        .select('id')
        .single();

    final requestId = row['id'] as String;
    await _client.from('service_request_equipment').insert([
      for (final equipmentId in equipmentIds)
        {'request_id': requestId, 'equipment_id': equipmentId},
    ]);
  }

  Future<void> assignSchedule({
    required String requestId,
    required DateTime scheduledAt,
  }) {
    return _client.from('service_requests').update({
      'status': 'scheduled',
      'scheduled_at': scheduledAt.toIso8601String(),
    }).eq('id', requestId);
  }

  Future<void> saveTechnicianComment({
    required String requestId,
    required String comment,
  }) {
    return _client
        .from('service_requests')
        .update({'technician_comment': comment}).eq('id', requestId);
  }

  /// Закрывает заявку — стоимость ремонта (доход) и запчастей (расход)
  /// обязательны, см. вкладку "Статистика" у администратора.
  Future<void> markDone({
    required String requestId,
    required double repairCost,
    required double partsCost,
  }) {
    return _client.from('service_requests').update({
      'status': 'done',
      'completed_at': DateTime.now().toIso8601String(),
      'repair_cost': repairCost,
      'parts_cost': partsCost,
    }).eq('id', requestId);
  }

  Future<void> cancel({required String requestId}) {
    return _client
        .from('service_requests')
        .update({'status': 'cancelled'}).eq('id', requestId);
  }

  /// Закрытые заявки за период (по дате закрытия) — только нужные для
  /// статистики поля, без тяжёлых join'ов fetchAll(). Только
  /// администратору RLS отдаст заявки не своего заведения, но этот
  /// метод и вызывается только с экрана статистики администратора.
  Future<List<ServiceRequest>> fetchClosedInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await _client
        .from('service_requests')
        .select()
        .eq('status', 'done')
        .gte('completed_at', start.toIso8601String())
        .lte('completed_at', end.toIso8601String())
        .order('completed_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => ServiceRequest.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
