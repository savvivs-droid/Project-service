import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_request_list_item.dart';
import 'supabase_service.dart';

class ServiceRequestRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Все заявки со всех заведений — доступно только администратору
  /// (клиента RLS на уровне базы отфильтрует до его собственного
  /// заведения, даже если бы этот метод вызвали из-под клиента).
  Future<List<AdminRequestListItem>> fetchAllForAdmin() async {
    final data = await _client
        .from('service_requests')
        .select(
          '*, establishments(name, address), profiles(full_name, phone), '
          'service_request_equipment(equipment(type, sticker_code))',
        )
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) =>
            AdminRequestListItem.fromJson(row as Map<String, dynamic>))
        .toList();
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
