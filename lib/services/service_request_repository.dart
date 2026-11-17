import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/request_list_item.dart';
import '../models/service_request.dart';
import 'supabase_service.dart';

class ServiceRequestRepository {
  final SupabaseClient _client = SupabaseService.client;

  static const _listItemSelect = '*, establishments(name, address), '
      'profiles!service_requests_client_id_fkey(full_name, phone), '
      'service_request_equipment(equipment(*))';

  /// Одна заявка со всем, что нужно экрану детали — для перехода по
  /// нажатию на push о смене статуса. null — заявки нет или она не
  /// видна текущему пользователю (RLS).
  Future<RequestListItem?> fetchById(String requestId) async {
    final row = await _client
        .from('service_requests')
        .select(_listItemSelect)
        .eq('id', requestId)
        .maybeSingle();
    return row == null ? null : RequestListItem.fromJson(row);
  }

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
    final query = _client.from('service_requests').select(_listItemSelect);

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

  /// Назначает визит: техник, начало (ровный час) и длительность.
  /// Время уходит в базу в UTC — иначе timestamptz принял бы "голое"
  /// локальное время за UTC и визит сдвинулся бы на час-два.
  Future<void> assignVisit({
    required String requestId,
    required String technicianId,
    required DateTime start,
    required int durationHours,
  }) {
    return _client.from('service_requests').update({
      'status': 'scheduled',
      'scheduled_at': start.toUtc().toIso8601String(),
      'technician_id': technicianId,
      'duration_hours': durationHours,
    }).eq('id', requestId);
  }

  /// Визиты (запланированные и уже выполненные), которые начинаются в
  /// промежутке [from, to) — для сетки планировщика на день.
  Future<List<RequestListItem>> fetchVisitsBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _client
        .from('service_requests')
        .select(_listItemSelect)
        .inFilter('status', ['scheduled', 'done'])
        .gte('scheduled_at', from.toUtc().toIso8601String())
        .lt('scheduled_at', to.toUtc().toIso8601String())
        .order('scheduled_at');
    return (data as List<dynamic>)
        .map((row) => RequestListItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Заявки, которым ещё не назначен техник: новые и те, кому время
  /// назначили до появления планировщика (без техника).
  Future<List<RequestListItem>> fetchUnassigned() async {
    final data = await _client
        .from('service_requests')
        .select(_listItemSelect)
        .or('status.eq.new,and(status.eq.scheduled,technician_id.is.null)')
        .order('created_at');
    return (data as List<dynamic>)
        .map((row) => RequestListItem.fromJson(row as Map<String, dynamic>))
        .toList();
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
