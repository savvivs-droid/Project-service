import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/equipment_status.dart';
import '../models/equipment.dart';
import 'supabase_service.dart';

class EquipmentRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Equipment>> fetchForEstablishment(String establishmentId) async {
    final data = await _client
        .from('equipment')
        .select()
        .eq('establishment_id', establishmentId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => Equipment.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String establishmentId,
    required String type,
    required EquipmentStatus status,
    String? model,
    String? stickerCode,
    DateTime? installedAt,
  }) {
    return _client.from('equipment').insert({
      'establishment_id': establishmentId,
      'type': type,
      'model': model,
      'sticker_code': stickerCode,
      'installed_at': _formatDate(installedAt),
      'status': status.value,
    });
  }

  Future<void> update({
    required String id,
    required String type,
    required EquipmentStatus status,
    String? model,
    String? stickerCode,
    DateTime? installedAt,
  }) {
    return _client.from('equipment').update({
      'type': type,
      'model': model,
      'sticker_code': stickerCode,
      'installed_at': _formatDate(installedAt),
      'status': status.value,
    }).eq('id', id);
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
