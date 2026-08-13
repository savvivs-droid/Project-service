import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/establishment.dart';
import 'supabase_service.dart';

class EstablishmentRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Все заведения — доступно только администратору (клиента RLS
  /// отфильтрует до его собственного заведения).
  Future<List<Establishment>> fetchAllForAdmin() async {
    final data = await _client
        .from('establishments')
        .select()
        .order('connected_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => Establishment.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateEntrancePhoto({
    required String id,
    required String? entrancePhotoUrl,
  }) {
    return _client
        .from('establishments')
        .update({'entrance_photo_url': entrancePhotoUrl}).eq('id', id);
  }
}
