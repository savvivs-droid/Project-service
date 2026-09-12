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

  /// Все заведения, где состоит текущий клиент (может быть больше одного —
  /// см. establishment_members в supabase/schema.sql). Порядок — по
  /// давности членства, самое старое (обычно заведённое при регистрации)
  /// первым.
  Future<List<Establishment>> fetchForCurrentClient() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('establishment_members')
        .select('establishments(*)')
        .eq('profile_id', userId)
        .order('created_at');

    return (data as List<dynamic>)
        .map((row) => Establishment.fromJson(
            (row as Map<String, dynamic>)['establishments']
                as Map<String, dynamic>))
        .toList();
  }

  /// Клиент заводит себе ещё одно заведение (в дополнение к тем, что уже
  /// есть) — тот же принцип, что при регистрации: IČO, название, адрес,
  /// контактный телефон. Выполняется через add_client_establishment
  /// (security definer), потому что обычная insert-политика на
  /// establishments разрешена только администратору.
  Future<Establishment> addForCurrentClient({
    required String name,
    required String address,
    required String contactPhone,
  }) async {
    final id = await _client.rpc('add_client_establishment', params: {
      'p_ico': null,
      'p_name': name,
      'p_address': address,
      'p_contact_phone': contactPhone,
    }) as String;

    final row =
        await _client.from('establishments').select().eq('id', id).single();
    return Establishment.fromJson(row);
  }
}
