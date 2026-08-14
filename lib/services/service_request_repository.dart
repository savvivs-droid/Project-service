import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/request_list_item.dart';
import 'supabase_service.dart';

class ServiceRequestRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Заявки, видимые текущему пользователю. Один и тот же запрос — RLS
  /// на уровне базы сам решает, что вернуть: администратору видны все
  /// заявки, клиенту — только заявки его собственного заведения.
  Future<List<RequestListItem>> fetchAll() async {
    final data = await _client
        .from('service_requests')
        .select(
          '*, establishments(name, address), profiles(full_name, phone), '
          'service_request_equipment(equipment(type, sticker_code))',
        )
        .order('created_at', ascending: false);

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

  Future<void> markDone({required String requestId}) {
    return _client.from('service_requests').update({
      'status': 'done',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  Future<void> cancel({required String requestId}) {
    return _client
        .from('service_requests')
        .update({'status': 'cancelled'}).eq('id', requestId);
  }
}
